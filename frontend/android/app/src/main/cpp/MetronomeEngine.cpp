#include "MetronomeEngine.h"
#include <android/log.h>
#include <cmath>
#include <algorithm>

#define LOG_TAG "MetronomeEngine"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

MetronomeEngine::MetronomeEngine() {
    LOGD("MetronomeEngine created");
}

MetronomeEngine::~MetronomeEngine() {
    dispose();
    LOGD("MetronomeEngine destroyed");
}

bool MetronomeEngine::init(int bpm, int beatsPerMeasure, const std::string& accentPattern,
                           int subdivision, const std::vector<bool>& soundPattern) {
    std::lock_guard<std::mutex> lock(mMutex);

    mBpm.store(bpm);
    mBeatsPerMeasure.store(beatsPerMeasure);
    mAccentPattern = accentPattern;
    mSubdivision.store(subdivision);
    mSoundPattern = soundPattern.empty() ? std::vector<bool>{true} : soundPattern;

    LOGD("MetronomeEngine initialized: bpm=%d, beatsPerMeasure=%d, subdivision=%d",
         bpm, beatsPerMeasure, subdivision);

    return true;
}

void MetronomeEngine::loadSounds(const std::vector<int16_t>& strongSound,
                                  const std::vector<int16_t>& mediumSound,
                                  const std::vector<int16_t>& weakSound) {
    std::lock_guard<std::mutex> lock(mMutex);

    mStrongBuffer = strongSound;
    mMediumBuffer = mediumSound;
    mWeakBuffer = weakSound;

    LOGD("Sounds loaded: strong=%zu, medium=%zu, weak=%zu samples",
         mStrongBuffer.size(), mMediumBuffer.size(), mWeakBuffer.size());
}

bool MetronomeEngine::start() {
    if (mIsPlaying.load()) {
        LOGD("Already playing");
        return true;
    }

    LOGD("Starting metronome");

    // Create Oboe stream
    oboe::AudioStreamBuilder builder;
    builder.setDirection(oboe::Direction::Output)
           ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
           ->setSharingMode(oboe::SharingMode::Exclusive)
           ->setFormat(oboe::AudioFormat::I16)
           ->setChannelCount(kChannelCount)
           ->setSampleRate(kSampleRate)
           ->setDataCallback(this);

    oboe::Result result = builder.openStream(mStream);
    if (result != oboe::Result::OK) {
        LOGE("Failed to open stream: %s", oboe::convertToText(result));
        return false;
    }

    LOGD("Stream opened: sampleRate=%d, channelCount=%d, framesPerBurst=%d",
         mStream->getSampleRate(), mStream->getChannelCount(),
         mStream->getFramesPerBurst());

    // Reset beat tracking
    mCurrentBeat = 0;
    mCurrentSubBeat = 0;
    mSamplesUntilNextBeat = 0;  // Trigger immediately
    mCurrentSamplePosition = 0;
    mCurrentPlayingBuffer = nullptr;
    mCurrentPlayingPosition = 0;
    mCurrentPlayingLength = 0;

    mIsPlaying.store(true);

    // Start UI callback thread
    mUiCallbackRunning.store(true);
    mUiCallbackThread = std::thread(&MetronomeEngine::uiCallbackLoop, this);

    // Start the stream
    result = mStream->requestStart();
    if (result != oboe::Result::OK) {
        LOGE("Failed to start stream: %s", oboe::convertToText(result));
        mIsPlaying.store(false);
        mUiCallbackRunning.store(false);
        if (mUiCallbackThread.joinable()) {
            mUiCallbackThread.join();
        }
        return false;
    }

    LOGD("Metronome started");
    return true;
}

void MetronomeEngine::stop() {
    if (!mIsPlaying.load()) {
        return;
    }

    LOGD("Stopping metronome");
    mIsPlaying.store(false);

    // Stop UI callback thread
    mUiCallbackRunning.store(false);
    if (mUiCallbackThread.joinable()) {
        mUiCallbackThread.join();
    }

    if (mStream) {
        mStream->requestStop();
        mStream->close();
        mStream.reset();
    }

    mCurrentBeat = 0;
    mCurrentSubBeat = 0;

    LOGD("Metronome stopped");
}

void MetronomeEngine::setBpm(int bpm) {
    mBpm.store(std::clamp(bpm, 30, 300));
    LOGD("BPM set to %d", mBpm.load());
}

void MetronomeEngine::setBeatsPerMeasure(int beats) {
    mBeatsPerMeasure.store(beats);
    LOGD("Beats per measure set to %d", beats);
}

void MetronomeEngine::setAccentPattern(const std::string& pattern) {
    std::lock_guard<std::mutex> lock(mMutex);
    mAccentPattern = pattern;
    LOGD("Accent pattern set to %s", pattern.c_str());
}

void MetronomeEngine::setSubdivision(int subdivision) {
    mSubdivision.store(std::clamp(subdivision, 1, 8));
    LOGD("Subdivision set to %d", mSubdivision.load());
}

void MetronomeEngine::setSoundPattern(const std::vector<bool>& pattern) {
    std::lock_guard<std::mutex> lock(mMutex);
    mSoundPattern = pattern.empty() ? std::vector<bool>{true} : pattern;
    LOGD("Sound pattern set, size=%zu", mSoundPattern.size());
}

void MetronomeEngine::playTapSound() {
    mPlayTapSound.store(true);
}

void MetronomeEngine::setBeatCallback(BeatCallback callback) {
    mBeatCallback = std::move(callback);
}

void MetronomeEngine::setSubdivisionCallback(SubdivisionCallback callback) {
    mSubdivisionCallback = std::move(callback);
}

void MetronomeEngine::dispose() {
    stop();

    std::lock_guard<std::mutex> lock(mMutex);
    mStrongBuffer.clear();
    mMediumBuffer.clear();
    mWeakBuffer.clear();
    mBeatCallback = nullptr;
    mSubdivisionCallback = nullptr;

    LOGD("MetronomeEngine disposed");
}

oboe::DataCallbackResult MetronomeEngine::onAudioReady(
    oboe::AudioStream* stream,
    void* audioData,
    int32_t numFrames) {

    if (!mIsPlaying.load()) {
        return oboe::DataCallbackResult::Stop;
    }

    auto* output = static_cast<int16_t*>(audioData);
    const int32_t numSamples = numFrames * kChannelCount;

    // Clear output buffer
    std::fill(output, output + numSamples, 0);

    int64_t samplesPerSubdiv = calculateSamplesPerSubdivision();

    for (int32_t frame = 0; frame < numFrames; ++frame) {
        // Check if we need to trigger a new beat
        if (mSamplesUntilNextBeat <= 0) {
            advanceBeat();
            mSamplesUntilNextBeat = samplesPerSubdiv;

            // Select buffer for this beat
            BeatType beatType = getBeatType(mCurrentBeat);
            mCurrentPlayingBuffer = selectBuffer(mCurrentBeat, mCurrentSubBeat, beatType);
            mCurrentPlayingLength = selectBufferLength(mCurrentBeat, mCurrentSubBeat, beatType);
            mCurrentPlayingPosition = 0;
        }

        // Mix current playing buffer into output
        if (mCurrentPlayingBuffer && mCurrentPlayingPosition < mCurrentPlayingLength) {
            size_t sampleIndex = mCurrentPlayingPosition;
            // Assuming stereo sound buffers
            if (sampleIndex + 1 < mCurrentPlayingLength) {
                output[frame * 2] = mCurrentPlayingBuffer[sampleIndex];
                output[frame * 2 + 1] = mCurrentPlayingBuffer[sampleIndex + 1];
            }
            mCurrentPlayingPosition += kChannelCount;
        }

        // Handle tap sound overlay
        if (mPlayTapSound.load()) {
            if (mTapSoundBuffer == nullptr) {
                mTapSoundBuffer = mStrongBuffer.data();
                mTapSoundLength = mStrongBuffer.size();
                mTapSoundPosition = 0;
                mPlayTapSound.store(false);
            }
        }

        if (mTapSoundBuffer && mTapSoundPosition < mTapSoundLength) {
            size_t sampleIndex = mTapSoundPosition;
            if (sampleIndex + 1 < mTapSoundLength) {
                // Mix tap sound (with clipping prevention)
                int32_t left = output[frame * 2] + mTapSoundBuffer[sampleIndex];
                int32_t right = output[frame * 2 + 1] + mTapSoundBuffer[sampleIndex + 1];
                output[frame * 2] = static_cast<int16_t>(std::clamp(left, -32768, 32767));
                output[frame * 2 + 1] = static_cast<int16_t>(std::clamp(right, -32768, 32767));
            }
            mTapSoundPosition += kChannelCount;
            if (mTapSoundPosition >= mTapSoundLength) {
                mTapSoundBuffer = nullptr;
            }
        }

        mSamplesUntilNextBeat--;
        mCurrentSamplePosition++;
    }

    return oboe::DataCallbackResult::Continue;
}

int64_t MetronomeEngine::calculateSamplesPerSubdivision() const {
    int bpm = mBpm.load();
    int subdivision = mSubdivision.load();

    // Samples per beat = sample rate * 60 / BPM
    double samplesPerBeat = static_cast<double>(kSampleRate) * 60.0 / static_cast<double>(bpm);

    // Samples per subdivision
    return static_cast<int64_t>(samplesPerBeat / static_cast<double>(subdivision));
}

BeatType MetronomeEngine::getBeatType(int beat) const {
    std::string pattern;
    {
        std::lock_guard<std::mutex> lock(const_cast<std::mutex&>(mMutex));
        pattern = mAccentPattern;
    }

    if (pattern == "uniform") {
        return BeatType::MEDIUM;
    } else if (pattern == "firstBeatOnly") {
        return beat == 1 ? BeatType::STRONG : BeatType::WEAK;
    } else if (pattern == "strongMediumWeak") {
        if (beat == 1) return BeatType::STRONG;
        int beatsPerMeasure = mBeatsPerMeasure.load();
        if (beatsPerMeasure == 4 && beat == 3) return BeatType::MEDIUM;
        if (beatsPerMeasure == 6 && beat == 4) return BeatType::MEDIUM;
        return BeatType::WEAK;
    }

    return beat == 1 ? BeatType::STRONG : BeatType::WEAK;
}

const int16_t* MetronomeEngine::selectBuffer(int beat, int subBeat, BeatType beatType) const {
    // Check sound pattern (subBeat is 1-indexed)
    std::vector<bool> pattern;
    {
        std::lock_guard<std::mutex> lock(const_cast<std::mutex&>(mMutex));
        pattern = mSoundPattern;
    }

    int patternIndex = (subBeat - 1) % pattern.size();
    if (!pattern[patternIndex]) {
        return nullptr;  // Rest - no sound
    }

    // Main beat or subdivision?
    bool isMainBeat = subBeat == 1;

    if (!isMainBeat) {
        return mWeakBuffer.data();  // Subdivisions always use weak
    }

    // Main beat - select based on beat type
    switch (beatType) {
        case BeatType::STRONG:
            return mStrongBuffer.data();
        case BeatType::MEDIUM:
            return mMediumBuffer.data();
        case BeatType::WEAK:
        default:
            return mWeakBuffer.data();
    }
}

size_t MetronomeEngine::selectBufferLength(int beat, int subBeat, BeatType beatType) const {
    // Check sound pattern (subBeat is 1-indexed)
    std::vector<bool> pattern;
    {
        std::lock_guard<std::mutex> lock(const_cast<std::mutex&>(mMutex));
        pattern = mSoundPattern;
    }

    int patternIndex = (subBeat - 1) % pattern.size();
    if (!pattern[patternIndex]) {
        return 0;  // Rest - no sound
    }

    bool isMainBeat = subBeat == 1;

    if (!isMainBeat) {
        return mWeakBuffer.size();
    }

    switch (beatType) {
        case BeatType::STRONG:
            return mStrongBuffer.size();
        case BeatType::MEDIUM:
            return mMediumBuffer.size();
        case BeatType::WEAK:
        default:
            return mWeakBuffer.size();
    }
}

void MetronomeEngine::advanceBeat() {
    int subdivision = mSubdivision.load();
    int beatsPerMeasure = mBeatsPerMeasure.load();

    mCurrentSubBeat++;
    if (mCurrentSubBeat > subdivision) {
        mCurrentSubBeat = 1;
        mCurrentBeat = (mCurrentBeat % beatsPerMeasure) + 1;
    }
}

void MetronomeEngine::uiCallbackLoop() {
    LOGD("UI callback thread started");

    // Calculate interval for subdivision ticks
    while (mUiCallbackRunning.load()) {
        int bpm = mBpm.load();
        int subdivision = mSubdivision.load();

        // Milliseconds per subdivision
        double msPerSubdiv = 60000.0 / (double)bpm / (double)subdivision;
        auto interval = std::chrono::microseconds(static_cast<int64_t>(msPerSubdiv * 1000));

        auto nextTick = std::chrono::steady_clock::now() + interval;

        // Wait for next tick
        std::this_thread::sleep_until(nextTick);

        if (!mIsPlaying.load() || !mUiCallbackRunning.load()) {
            break;
        }

        // Get current beat state (synchronized with audio)
        int beat = mCurrentBeat;
        int subBeat = mCurrentSubBeat;
        bool isMainBeat = subBeat == 1;

        // Check if this is an accent beat
        BeatType beatType = getBeatType(beat);
        bool isAccent = isMainBeat && beatType == BeatType::STRONG;

        // Call subdivision callback
        if (mSubdivisionCallback) {
            mSubdivisionCallback(subBeat - 1, isMainBeat);  // 0-indexed for Flutter
        }

        // Call beat callback on main beats
        if (isMainBeat && mBeatCallback) {
            mBeatCallback(beat, isAccent);
        }
    }

    LOGD("UI callback thread stopped");
}
