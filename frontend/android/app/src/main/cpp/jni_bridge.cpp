#include <jni.h>
#include <string>
#include <android/log.h>
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include "MetronomeEngine.h"

#define LOG_TAG "MetronomeJNI"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Global engine instance
static std::unique_ptr<MetronomeEngine> gEngine;

// Global references for callbacks
static JavaVM* gJavaVM = nullptr;
static jobject gCallbackObject = nullptr;
static jmethodID gOnBeatMethod = nullptr;
static jmethodID gOnSubdivisionMethod = nullptr;

// Helper to get JNIEnv
JNIEnv* getJNIEnv() {
    JNIEnv* env = nullptr;
    if (gJavaVM) {
        if (gJavaVM->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) == JNI_EDETACHED) {
            gJavaVM->AttachCurrentThread(&env, nullptr);
        }
    }
    return env;
}

// Parse WAV file and extract PCM data
std::vector<int16_t> parseWavToPcm(const std::vector<uint8_t>& wavData) {
    if (wavData.size() < 44) {
        LOGE("WAV data too small: %zu bytes", wavData.size());
        return {};
    }

    // WAV header is 44 bytes for standard PCM
    const uint8_t* pcmStart = wavData.data() + 44;
    size_t pcmSize = wavData.size() - 44;

    // Convert bytes to shorts (16-bit PCM, little-endian)
    std::vector<int16_t> pcmData(pcmSize / 2);
    for (size_t i = 0; i < pcmData.size(); ++i) {
        pcmData[i] = static_cast<int16_t>(
            pcmStart[i * 2] | (pcmStart[i * 2 + 1] << 8)
        );
    }

    return pcmData;
}

// Load asset and parse WAV
std::vector<int16_t> loadSoundFromAsset(JNIEnv* env, jobject assetManager, const std::string& path) {
    AAssetManager* mgr = AAssetManager_fromJava(env, assetManager);
    if (!mgr) {
        LOGE("Failed to get AAssetManager");
        return {};
    }

    // Flutter assets path
    std::string assetPath = "flutter_assets/" + path;
    AAsset* asset = AAssetManager_open(mgr, assetPath.c_str(), AASSET_MODE_BUFFER);

    if (!asset) {
        // Try with assets/ prefix
        assetPath = "flutter_assets/assets/" + path;
        asset = AAssetManager_open(mgr, assetPath.c_str(), AASSET_MODE_BUFFER);
    }

    if (!asset) {
        LOGE("Failed to open asset: %s", path.c_str());
        return {};
    }

    off_t length = AAsset_getLength(asset);
    std::vector<uint8_t> buffer(length);
    AAsset_read(asset, buffer.data(), length);
    AAsset_close(asset);

    LOGD("Loaded asset %s: %ld bytes", path.c_str(), length);
    return parseWavToPcm(buffer);
}

extern "C" {

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void* reserved) {
    gJavaVM = vm;
    LOGD("JNI_OnLoad");
    return JNI_VERSION_1_6;
}

JNIEXPORT void JNICALL JNI_OnUnload(JavaVM* vm, void* reserved) {
    LOGD("JNI_OnUnload");
    gJavaVM = nullptr;
}

JNIEXPORT jboolean JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeInit(
    JNIEnv* env,
    jobject thiz,
    jint bpm,
    jint beatsPerMeasure,
    jstring accentPattern,
    jint subdivision,
    jbooleanArray soundPattern,
    jobject assetManager,
    jstring strongSound,
    jstring mediumSound,
    jstring weakSound) {

    LOGD("nativeInit called");

    // Create engine if needed
    if (!gEngine) {
        gEngine = std::make_unique<MetronomeEngine>();
    }

    // Convert accent pattern
    const char* patternCStr = env->GetStringUTFChars(accentPattern, nullptr);
    std::string pattern(patternCStr);
    env->ReleaseStringUTFChars(accentPattern, patternCStr);

    // Convert sound pattern
    jsize patternLen = env->GetArrayLength(soundPattern);
    jboolean* patternArr = env->GetBooleanArrayElements(soundPattern, nullptr);
    std::vector<bool> soundPatternVec(patternLen);
    for (jsize i = 0; i < patternLen; ++i) {
        soundPatternVec[i] = patternArr[i];
    }
    env->ReleaseBooleanArrayElements(soundPattern, patternArr, 0);

    // Initialize engine
    bool success = gEngine->init(bpm, beatsPerMeasure, pattern, subdivision, soundPatternVec);

    // Load sounds
    const char* strongPath = env->GetStringUTFChars(strongSound, nullptr);
    const char* mediumPath = env->GetStringUTFChars(mediumSound, nullptr);
    const char* weakPath = env->GetStringUTFChars(weakSound, nullptr);

    auto strongBuffer = loadSoundFromAsset(env, assetManager, strongPath);
    auto mediumBuffer = loadSoundFromAsset(env, assetManager, mediumPath);
    auto weakBuffer = loadSoundFromAsset(env, assetManager, weakPath);

    env->ReleaseStringUTFChars(strongSound, strongPath);
    env->ReleaseStringUTFChars(mediumSound, mediumPath);
    env->ReleaseStringUTFChars(weakSound, weakPath);

    gEngine->loadSounds(strongBuffer, mediumBuffer, weakBuffer);

    // Store callback object
    if (gCallbackObject) {
        env->DeleteGlobalRef(gCallbackObject);
    }
    gCallbackObject = env->NewGlobalRef(thiz);

    // Get callback method IDs
    jclass clazz = env->GetObjectClass(thiz);
    gOnBeatMethod = env->GetMethodID(clazz, "onBeatCallback", "(IZ)V");
    gOnSubdivisionMethod = env->GetMethodID(clazz, "onSubdivisionCallback", "(IZ)V");

    // Set callbacks
    gEngine->setBeatCallback([](int beat, bool isAccent) {
        JNIEnv* env = getJNIEnv();
        if (env && gCallbackObject && gOnBeatMethod) {
            env->CallVoidMethod(gCallbackObject, gOnBeatMethod, beat, isAccent);
        }
    });

    gEngine->setSubdivisionCallback([](int subBeat, bool isMainBeat) {
        JNIEnv* env = getJNIEnv();
        if (env && gCallbackObject && gOnSubdivisionMethod) {
            env->CallVoidMethod(gCallbackObject, gOnSubdivisionMethod, subBeat, isMainBeat);
        }
    });

    LOGD("nativeInit completed: %s", success ? "true" : "false");
    return success ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jboolean JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeStart(
    JNIEnv* env,
    jobject thiz) {
    LOGD("nativeStart");
    if (gEngine) {
        return gEngine->start() ? JNI_TRUE : JNI_FALSE;
    }
    return JNI_FALSE;
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeStop(
    JNIEnv* env,
    jobject thiz) {
    LOGD("nativeStop");
    if (gEngine) {
        gEngine->stop();
    }
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeSetBpm(
    JNIEnv* env,
    jobject thiz,
    jint bpm) {
    if (gEngine) {
        gEngine->setBpm(bpm);
    }
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeSetBeatsPerMeasure(
    JNIEnv* env,
    jobject thiz,
    jint beats) {
    if (gEngine) {
        gEngine->setBeatsPerMeasure(beats);
    }
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeSetAccentPattern(
    JNIEnv* env,
    jobject thiz,
    jstring pattern) {
    if (gEngine) {
        const char* patternCStr = env->GetStringUTFChars(pattern, nullptr);
        gEngine->setAccentPattern(patternCStr);
        env->ReleaseStringUTFChars(pattern, patternCStr);
    }
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeSetSubdivision(
    JNIEnv* env,
    jobject thiz,
    jint subdivision) {
    if (gEngine) {
        gEngine->setSubdivision(subdivision);
    }
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeSetSoundPattern(
    JNIEnv* env,
    jobject thiz,
    jbooleanArray pattern) {
    if (gEngine) {
        jsize len = env->GetArrayLength(pattern);
        jboolean* arr = env->GetBooleanArrayElements(pattern, nullptr);
        std::vector<bool> patternVec(len);
        for (jsize i = 0; i < len; ++i) {
            patternVec[i] = arr[i];
        }
        env->ReleaseBooleanArrayElements(pattern, arr, 0);
        gEngine->setSoundPattern(patternVec);
    }
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeLoadSounds(
    JNIEnv* env,
    jobject thiz,
    jobject assetManager,
    jstring strongSound,
    jstring mediumSound,
    jstring weakSound) {
    if (!gEngine) return;

    const char* strongPath = env->GetStringUTFChars(strongSound, nullptr);
    const char* mediumPath = env->GetStringUTFChars(mediumSound, nullptr);
    const char* weakPath = env->GetStringUTFChars(weakSound, nullptr);

    auto strongBuffer = loadSoundFromAsset(env, assetManager, strongPath);
    auto mediumBuffer = loadSoundFromAsset(env, assetManager, mediumPath);
    auto weakBuffer = loadSoundFromAsset(env, assetManager, weakPath);

    env->ReleaseStringUTFChars(strongSound, strongPath);
    env->ReleaseStringUTFChars(mediumSound, mediumPath);
    env->ReleaseStringUTFChars(weakSound, weakPath);

    gEngine->loadSounds(strongBuffer, mediumBuffer, weakBuffer);
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativePlayTapSound(
    JNIEnv* env,
    jobject thiz) {
    if (gEngine) {
        gEngine->playTapSound();
    }
}

JNIEXPORT void JNICALL
Java_com_lessonapp_lesson_1app_audio_OboeMetronomeEngine_nativeDispose(
    JNIEnv* env,
    jobject thiz) {
    LOGD("nativeDispose");
    if (gEngine) {
        gEngine->dispose();
        gEngine.reset();
    }
    if (gCallbackObject) {
        env->DeleteGlobalRef(gCallbackObject);
        gCallbackObject = nullptr;
    }
}

} // extern "C"
