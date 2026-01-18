package com.lessonapp.lesson_app.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Handler
import android.os.HandlerThread
import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Beat type for accent patterns.
 */
enum class BeatType {
    STRONG, MEDIUM, WEAK
}

/**
 * Callback type for beat events.
 */
typealias BeatCallback = (Int, Boolean) -> Unit

/**
 * High-precision metronome engine using AudioTrack with LOW_LATENCY mode.
 *
 * Uses PCM frame counting for precise timing:
 * - Writes click sounds directly to AudioTrack stream
 * - Calculates exact frame positions for each beat
 * - Fills silence between beats
 */
class MetronomeAudioEngine(
    private val context: Context,
    private var bpm: Int,
    private var beatsPerMeasure: Int,
    private var accentPattern: String,
    strongSoundPath: String,
    mediumSoundPath: String,
    weakSoundPath: String
) {
    companion object {
        private const val SAMPLE_RATE = 44100
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_OUT_STEREO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    }

    // Audio components
    private var audioTrack: AudioTrack? = null
    private var audioThread: HandlerThread? = null
    private var audioHandler: Handler? = null

    // Sound buffers (PCM data)
    private var strongBuffer: ShortArray = ShortArray(0)
    private var mediumBuffer: ShortArray = ShortArray(0)
    private var weakBuffer: ShortArray = ShortArray(0)

    // Playback state
    @Volatile
    private var isRunning = false
    private var currentBeat = 0

    // Callback
    var onBeat: BeatCallback? = null

    init {
        loadSounds(strongSoundPath, mediumSoundPath, weakSoundPath)
    }

    // MARK: - Sound Loading

    fun loadSounds(strongPath: String, mediumPath: String, weakPath: String) {
        strongBuffer = loadSound(strongPath)
        mediumBuffer = loadSound(mediumPath)
        weakBuffer = loadSound(weakPath)
    }

    private fun loadSound(assetPath: String): ShortArray {
        if (assetPath.isEmpty()) return ShortArray(0)

        return try {
            // Flutter assets path: flutter_assets/assets/...
            val flutterPath = if (assetPath.startsWith("assets/")) {
                "flutter_assets/$assetPath"
            } else {
                "flutter_assets/assets/$assetPath"
            }

            val inputStream: InputStream = context.assets.open(flutterPath)
            val wavData = inputStream.readBytes()
            inputStream.close()

            // Parse WAV and extract PCM data
            parseWavToPcm(wavData)
        } catch (e: Exception) {
            e.printStackTrace()
            ShortArray(0)
        }
    }

    private fun parseWavToPcm(wavData: ByteArray): ShortArray {
        // WAV header is 44 bytes
        if (wavData.size < 44) return ShortArray(0)

        // Skip WAV header and get PCM data
        val pcmData = wavData.copyOfRange(44, wavData.size)

        // Convert bytes to shorts (16-bit PCM)
        val shortBuffer = ShortArray(pcmData.size / 2)
        ByteBuffer.wrap(pcmData)
            .order(ByteOrder.LITTLE_ENDIAN)
            .asShortBuffer()
            .get(shortBuffer)

        return shortBuffer
    }

    // MARK: - AudioTrack Setup

    private fun setupAudioTrack() {
        val minBufferSize = AudioTrack.getMinBufferSize(
            SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT
        )

        // Use at least 100ms buffer (SAMPLE_RATE / 10 frames * 2 bytes * 2 channels)
        val desiredBufferSize = maxOf(minBufferSize, SAMPLE_RATE / 10 * 2 * 2)

        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(SAMPLE_RATE)
                    .setEncoding(AUDIO_FORMAT)
                    .setChannelMask(CHANNEL_CONFIG)
                    .build()
            )
            .setBufferSizeInBytes(desiredBufferSize)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
            .build()
    }

    // MARK: - Playback Control

    fun start() {
        if (isRunning) return

        // Setup audio thread
        audioThread = HandlerThread("MetronomeAudioThread").apply {
            start()
        }
        audioHandler = Handler(audioThread!!.looper)

        // Setup AudioTrack
        setupAudioTrack()

        isRunning = true
        currentBeat = 0

        audioTrack?.play()

        // Start audio loop
        audioHandler?.post { audioLoop() }
    }

    fun stop() {
        isRunning = false

        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null

        audioThread?.quitSafely()
        audioThread = null
        audioHandler = null

        currentBeat = 0
    }

    // MARK: - Audio Loop

    private fun audioLoop() {
        val track = audioTrack ?: return

        while (isRunning) {
            // Move to next beat
            currentBeat = (currentBeat % beatsPerMeasure) + 1

            // Get beat type and buffer
            val beatType = getBeatType(currentBeat)
            val clickBuffer = getBuffer(beatType)

            // Calculate frames per beat
            val framesPerBeat = SAMPLE_RATE * 60 / bpm

            // Write click sound
            if (clickBuffer.isNotEmpty()) {
                track.write(clickBuffer, 0, clickBuffer.size)
            }

            // Send beat event
            val isAccent = currentBeat == 1 && accentPattern != "uniform"
            onBeat?.invoke(currentBeat, isAccent)

            // Calculate silence needed to fill the beat interval
            val clickFrames = clickBuffer.size / 2  // stereo = 2 samples per frame
            val silenceFrames = framesPerBeat - clickFrames

            if (silenceFrames > 0) {
                // Write silence (zeros)
                val silenceBuffer = ShortArray(silenceFrames * 2)  // stereo
                track.write(silenceBuffer, 0, silenceBuffer.size)
            }
        }
    }

    private fun getBeatType(beat: Int): BeatType {
        return when (accentPattern) {
            "uniform" -> BeatType.MEDIUM

            "firstBeatOnly" -> {
                if (beat == 1) BeatType.STRONG else BeatType.WEAK
            }

            "strongMediumWeak" -> {
                when {
                    beat == 1 -> BeatType.STRONG
                    beatsPerMeasure == 4 && beat == 3 -> BeatType.MEDIUM
                    beatsPerMeasure == 6 && beat == 4 -> BeatType.MEDIUM
                    else -> BeatType.WEAK
                }
            }

            else -> if (beat == 1) BeatType.STRONG else BeatType.WEAK
        }
    }

    private fun getBuffer(beatType: BeatType): ShortArray {
        return when (beatType) {
            BeatType.STRONG -> strongBuffer
            BeatType.MEDIUM -> mediumBuffer
            BeatType.WEAK -> weakBuffer
        }
    }

    // MARK: - Settings

    fun setBpm(newBpm: Int) {
        bpm = newBpm.coerceIn(30, 208)
    }

    fun setTimeSignature(newBeatsPerMeasure: Int) {
        beatsPerMeasure = newBeatsPerMeasure
    }

    fun setAccentPattern(pattern: String) {
        accentPattern = pattern
    }

    // MARK: - Tap Sound

    fun playTapSound() {
        if (strongBuffer.isEmpty()) return

        // Create temporary track for tap sound
        val minBufferSize = AudioTrack.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
        val bufferSizeBytes = maxOf(minBufferSize, strongBuffer.size * 2)  // 2 bytes per short

        val tapTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(SAMPLE_RATE)
                    .setEncoding(AUDIO_FORMAT)
                    .setChannelMask(CHANNEL_CONFIG)
                    .build()
            )
            .setBufferSizeInBytes(bufferSizeBytes)
            .setTransferMode(AudioTrack.MODE_STATIC)
            .build()

        tapTrack.write(strongBuffer, 0, strongBuffer.size)
        tapTrack.play()

        // Release after playback
        Handler(context.mainLooper).postDelayed({
            tapTrack.stop()
            tapTrack.release()
        }, 500)
    }

    // MARK: - Cleanup

    fun dispose() {
        stop()
        strongBuffer = ShortArray(0)
        mediumBuffer = ShortArray(0)
        weakBuffer = ShortArray(0)
    }
}
