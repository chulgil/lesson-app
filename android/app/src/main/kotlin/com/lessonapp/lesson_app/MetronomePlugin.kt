package com.lessonapp.lesson_app

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.lessonapp.lesson_app.audio.OboeMetronomeEngine

/**
 * Flutter plugin for native metronome functionality using Oboe.
 * Uses low-latency Oboe audio engine for sample-accurate timing.
 */
class MetronomePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "MetronomePlugin"
    }

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var engine: OboeMetronomeEngine? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "com.lessonapp/metronome")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.lessonapp/metronome_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        engine?.dispose()
        engine = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "init" -> handleInit(call, result)
            "start" -> handleStart(result)
            "stop" -> handleStop(result)
            "setBpm" -> handleSetBpm(call, result)
            "setTimeSignature" -> handleSetTimeSignature(call, result)
            "setAccentPattern" -> handleSetAccentPattern(call, result)
            "setSubdivision" -> handleSetSubdivision(call, result)
            "setSoundPattern" -> handleSetSoundPattern(call, result)
            "setSound" -> handleSetSound(call, result)
            "playTapSound" -> handlePlayTapSound(result)
            "dispose" -> handleDispose(result)
            else -> result.notImplemented()
        }
    }

    // MARK: - Method Handlers

    private fun handleInit(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        val ctx = context
        if (ctx == null) {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        try {
            Log.d(TAG, "handleInit: Starting Oboe metronome initialization")

            val bpm = (args["bpm"] as? Number)?.toInt() ?: 120
            val beatsPerMeasure = (args["beatsPerMeasure"] as? Number)?.toInt() ?: 4
            val accentPattern = args["accentPattern"] as? String ?: "firstBeatOnly"
            val subdivision = (args["subdivision"] as? Number)?.toInt() ?: 1
            @Suppress("UNCHECKED_CAST")
            val soundPattern = (args["soundPattern"] as? List<Boolean>) ?: listOf(true)
            val strongSound = args["strongSound"] as? String ?: ""
            val mediumSound = args["mediumSound"] as? String ?: ""
            val weakSound = args["weakSound"] as? String ?: ""

            Log.d(TAG, "handleInit: bpm=$bpm, beats=$beatsPerMeasure, subdivision=$subdivision")

            engine = OboeMetronomeEngine(
                context = ctx,
                bpm = bpm,
                beatsPerMeasure = beatsPerMeasure,
                accentPattern = accentPattern,
                subdivision = subdivision,
                soundPattern = soundPattern,
                strongSoundPath = strongSound,
                mediumSoundPath = mediumSound,
                weakSoundPath = weakSound
            )

            // Set beat callback
            engine?.onBeat = { beat, isAccent ->
                eventSink?.success(mapOf(
                    "type" to "beat",
                    "beat" to beat,
                    "isAccent" to isAccent
                ))
            }

            // Set subdivision callback
            engine?.onSubdivision = { subBeat, isMainBeat ->
                eventSink?.success(mapOf(
                    "type" to "subdivision",
                    "subBeat" to subBeat,
                    "isMainBeat" to isMainBeat
                ))
            }

            Log.d(TAG, "handleInit: Oboe metronome initialized successfully")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "handleInit failed: ${e.message}", e)
            result.error("INIT_FAILED", e.message, null)
        }
    }

    private fun handleStart(result: Result) {
        val eng = engine
        if (eng == null) {
            result.error("NOT_INITIALIZED", "Engine not initialized", null)
            return
        }

        try {
            eng.start()
            result.success(true)
        } catch (e: Exception) {
            result.error("START_FAILED", e.message, null)
        }
    }

    private fun handleStop(result: Result) {
        engine?.stop()
        result.success(true)
    }

    private fun handleSetBpm(call: MethodCall, result: Result) {
        val bpm = call.arguments as? Int
        if (bpm == null) {
            result.error("INVALID_ARGS", "BPM must be an integer", null)
            return
        }

        engine?.setBpm(bpm)
        result.success(true)
    }

    private fun handleSetTimeSignature(call: MethodCall, result: Result) {
        val beatsPerMeasure = call.arguments as? Int
        if (beatsPerMeasure == null) {
            result.error("INVALID_ARGS", "beatsPerMeasure must be an integer", null)
            return
        }

        engine?.setTimeSignature(beatsPerMeasure)
        result.success(true)
    }

    private fun handleSetAccentPattern(call: MethodCall, result: Result) {
        val pattern = call.arguments as? String
        if (pattern == null) {
            result.error("INVALID_ARGS", "Pattern must be a string", null)
            return
        }

        engine?.setAccentPattern(pattern)
        result.success(true)
    }

    private fun handleSetSubdivision(call: MethodCall, result: Result) {
        val subdivision = call.arguments as? Int
        if (subdivision == null) {
            result.error("INVALID_ARGS", "Subdivision must be an integer", null)
            return
        }

        engine?.setSubdivision(subdivision)
        result.success(true)
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleSetSoundPattern(call: MethodCall, result: Result) {
        val pattern = call.arguments as? List<Boolean>
        if (pattern == null) {
            result.error("INVALID_ARGS", "SoundPattern must be a list of booleans", null)
            return
        }

        engine?.setSoundPattern(pattern)
        result.success(true)
    }

    private fun handleSetSound(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        try {
            val strongSound = args["strongSound"] as? String ?: ""
            val mediumSound = args["mediumSound"] as? String ?: ""
            val weakSound = args["weakSound"] as? String ?: ""

            engine?.loadSounds(strongSound, mediumSound, weakSound)
            result.success(true)
        } catch (e: Exception) {
            result.error("LOAD_FAILED", e.message, null)
        }
    }

    private fun handlePlayTapSound(result: Result) {
        engine?.playTapSound()
        result.success(true)
    }

    private fun handleDispose(result: Result) {
        engine?.dispose()
        engine = null
        result.success(true)
    }

    // MARK: - EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
