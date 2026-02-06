package com.lessonapp.lesson_app.audio

import android.content.Context
import android.content.res.AssetManager
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * Oboe-based metronome engine for low-latency audio playback.
 *
 * Uses native C++ code with Oboe library for sample-accurate timing.
 * Mirrors the iOS MetronomeAudioEngine functionality.
 */
class OboeMetronomeEngine(
    private val context: Context,
    private var bpm: Int,
    private var beatsPerMeasure: Int,
    private var accentPattern: String,
    private var subdivision: Int = 1,
    private var soundPattern: List<Boolean> = listOf(true),
    strongSoundPath: String,
    mediumSoundPath: String,
    weakSoundPath: String
) {
    companion object {
        private const val TAG = "OboeMetronomeEngine"

        init {
            System.loadLibrary("metronome_engine")
            Log.d(TAG, "Native library loaded")
        }
    }

    // Callbacks
    var onBeat: ((Int, Boolean) -> Unit)? = null
    var onSubdivision: ((Int, Boolean) -> Unit)? = null

    // Main thread handler for callbacks
    private val mainHandler = Handler(Looper.getMainLooper())

    // Track initialization state
    private var isInitialized = false

    init {
        val soundPatternArray = soundPattern.toBooleanArray()
        isInitialized = nativeInit(
            bpm,
            beatsPerMeasure,
            accentPattern,
            subdivision,
            soundPatternArray,
            context.assets,
            strongSoundPath,
            mediumSoundPath,
            weakSoundPath
        )

        if (isInitialized) {
            Log.d(TAG, "Engine initialized successfully")
        } else {
            Log.e(TAG, "Engine initialization failed")
        }
    }

    // Called from native code
    @Suppress("unused")
    fun onBeatCallback(beat: Int, isAccent: Boolean) {
        mainHandler.post {
            onBeat?.invoke(beat, isAccent)
        }
    }

    // Called from native code
    @Suppress("unused")
    fun onSubdivisionCallback(subBeat: Int, isMainBeat: Boolean) {
        mainHandler.post {
            onSubdivision?.invoke(subBeat, isMainBeat)
        }
    }

    fun start(): Boolean {
        if (!isInitialized) {
            Log.e(TAG, "Cannot start: not initialized")
            return false
        }
        return nativeStart()
    }

    fun stop() {
        nativeStop()
    }

    fun setBpm(newBpm: Int) {
        bpm = newBpm.coerceIn(30, 300)
        nativeSetBpm(bpm)
    }

    fun setTimeSignature(newBeatsPerMeasure: Int) {
        beatsPerMeasure = newBeatsPerMeasure
        nativeSetBeatsPerMeasure(newBeatsPerMeasure)
    }

    fun setAccentPattern(pattern: String) {
        accentPattern = pattern
        nativeSetAccentPattern(pattern)
    }

    fun setSubdivision(newSubdivision: Int) {
        subdivision = newSubdivision.coerceIn(1, 8)
        nativeSetSubdivision(subdivision)
    }

    fun setSoundPattern(pattern: List<Boolean>) {
        soundPattern = if (pattern.isEmpty()) listOf(true) else pattern
        nativeSetSoundPattern(soundPattern.toBooleanArray())
    }

    fun loadSounds(strongPath: String, mediumPath: String, weakPath: String) {
        nativeLoadSounds(context.assets, strongPath, mediumPath, weakPath)
    }

    fun playTapSound() {
        nativePlayTapSound()
    }

    fun dispose() {
        nativeDispose()
        isInitialized = false
    }

    // Native methods
    private external fun nativeInit(
        bpm: Int,
        beatsPerMeasure: Int,
        accentPattern: String,
        subdivision: Int,
        soundPattern: BooleanArray,
        assetManager: AssetManager,
        strongSound: String,
        mediumSound: String,
        weakSound: String
    ): Boolean

    private external fun nativeStart(): Boolean
    private external fun nativeStop()
    private external fun nativeSetBpm(bpm: Int)
    private external fun nativeSetBeatsPerMeasure(beats: Int)
    private external fun nativeSetAccentPattern(pattern: String)
    private external fun nativeSetSubdivision(subdivision: Int)
    private external fun nativeSetSoundPattern(pattern: BooleanArray)
    private external fun nativeLoadSounds(
        assetManager: AssetManager,
        strongSound: String,
        mediumSound: String,
        weakSound: String
    )
    private external fun nativePlayTapSound()
    private external fun nativeDispose()
}
