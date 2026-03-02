import Flutter
import UIKit

/// Flutter plugin for native metronome functionality.
/// Handles method channel calls and event channel for beat callbacks.
class MetronomePlugin: NSObject, FlutterPlugin {

    // MARK: - Properties

    private var audioEngine: MetronomeAudioEngine?
    private var eventSink: FlutterEventSink?

    // MARK: - Plugin Registration

    static func register(with registrar: FlutterPluginRegistrar) {
        debugPrint("MetronomePlugin: register")

        let instance = MetronomePlugin()

        // Method channel for commands
        let methodChannel = FlutterMethodChannel(
            name: "app.lessonaza/metronome",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        // Event channel for beat callbacks
        let eventChannel = FlutterEventChannel(
            name: "app.lessonaza/metronome_events",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)

        debugPrint("MetronomePlugin: registered successfully")
    }

    // MARK: - Method Call Handler

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        debugPrint("MetronomePlugin: handle \(call.method)")

        switch call.method {
        case "init":
            handleInit(call: call, result: result)
        case "start":
            handleStart(result: result)
        case "stop":
            handleStop(result: result)
        case "setBpm":
            handleSetBpm(call: call, result: result)
        case "setTimeSignature":
            handleSetTimeSignature(call: call, result: result)
        case "setAccentPattern":
            handleSetAccentPattern(call: call, result: result)
        case "setSubdivision":
            handleSetSubdivision(call: call, result: result)
        case "setSoundPattern":
            handleSetSoundPattern(call: call, result: result)
        case "setSound":
            handleSetSound(call: call, result: result)
        case "playTapSound":
            handlePlayTapSound(result: result)
        case "dispose":
            handleDispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Handlers

    private func handleInit(call: FlutterMethodCall, result: @escaping FlutterResult) {
        debugPrint("MetronomePlugin: handleInit")

        guard let args = call.arguments as? [String: Any] else {
            debugPrint("MetronomePlugin: Invalid arguments for init")
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let bpm = args["bpm"] as? Int ?? 120
        let beatsPerMeasure = args["beatsPerMeasure"] as? Int ?? 4
        let accentPattern = args["accentPattern"] as? String ?? "firstBeatOnly"
        let subdivision = args["subdivision"] as? Int ?? 1
        let soundPattern = args["soundPattern"] as? [Bool] ?? [true]
        let strongSound = args["strongSound"] as? String ?? "assets/sounds/metronome/click_strong.wav"
        let mediumSound = args["mediumSound"] as? String ?? "assets/sounds/metronome/click_medium.wav"
        let weakSound = args["weakSound"] as? String ?? "assets/sounds/metronome/click_weak.wav"

        debugPrint("MetronomePlugin: Creating audio engine")
        debugPrint("  BPM: \(bpm)")
        debugPrint("  beatsPerMeasure: \(beatsPerMeasure)")
        debugPrint("  subdivision: \(subdivision)")
        debugPrint("  soundPattern: \(soundPattern)")
        debugPrint("  strongSound: \(strongSound)")

        // Create audio engine
        audioEngine = MetronomeAudioEngine()

        // Setup callbacks
        audioEngine?.onBeat = { [weak self] beat, isAccent in
            self?.sendBeatEvent(beat: beat, isAccent: isAccent)
        }
        audioEngine?.onSubdivision = { [weak self] subBeat, isMainBeat in
            self?.sendSubdivisionEvent(subBeat: subBeat, isMainBeat: isMainBeat)
        }

        // Initialize
        do {
            try audioEngine?.setup(
                bpm: bpm,
                beatsPerMeasure: beatsPerMeasure,
                accentPattern: accentPattern,
                subdivision: subdivision,
                strongSoundPath: strongSound,
                mediumSoundPath: mediumSound,
                weakSoundPath: weakSound
            )
            // Set sound pattern after setup
            audioEngine?.setSoundPattern(soundPattern)
            debugPrint("MetronomePlugin: init success")
            result(true)
        } catch {
            debugPrint("MetronomePlugin: init failed - \(error.localizedDescription)")
            result(FlutterError(
                code: "INIT_FAILED",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    private func handleStart(result: @escaping FlutterResult) {
        debugPrint("MetronomePlugin: handleStart")
        audioEngine?.start()
        result(nil)
    }

    private func handleStop(result: @escaping FlutterResult) {
        debugPrint("MetronomePlugin: handleStop")
        audioEngine?.stop()
        result(nil)
    }

    private func handleSetBpm(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let bpm = call.arguments as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "BPM must be an integer", details: nil))
            return
        }
        debugPrint("MetronomePlugin: setBpm \(bpm)")
        audioEngine?.setBpm(bpm)
        result(nil)
    }

    private func handleSetTimeSignature(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let beatsPerMeasure = call.arguments as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "beatsPerMeasure must be an integer", details: nil))
            return
        }
        debugPrint("MetronomePlugin: setTimeSignature \(beatsPerMeasure)")
        audioEngine?.setBeatsPerMeasure(beatsPerMeasure)
        result(nil)
    }

    private func handleSetAccentPattern(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let pattern = call.arguments as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Pattern must be a string", details: nil))
            return
        }
        debugPrint("MetronomePlugin: setAccentPattern \(pattern)")
        audioEngine?.setAccentPattern(pattern)
        result(nil)
    }

    private func handleSetSubdivision(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let subdivision = call.arguments as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Subdivision must be an integer", details: nil))
            return
        }
        debugPrint("MetronomePlugin: setSubdivision \(subdivision)")
        audioEngine?.setSubdivision(subdivision)
        result(nil)
    }

    private func handleSetSoundPattern(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let pattern = call.arguments as? [Bool] else {
            result(FlutterError(code: "INVALID_ARGS", message: "SoundPattern must be a list of booleans", details: nil))
            return
        }
        debugPrint("MetronomePlugin: setSoundPattern \(pattern)")
        audioEngine?.setSoundPattern(pattern)
        result(nil)
    }

    private func handleSetSound(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        let strongSound = args["strongSound"] as? String ?? ""
        let mediumSound = args["mediumSound"] as? String ?? ""
        let weakSound = args["weakSound"] as? String ?? ""

        debugPrint("MetronomePlugin: setSound")

        do {
            try audioEngine?.updateSounds(
                strongPath: strongSound,
                mediumPath: mediumSound,
                weakPath: weakSound
            )
            result(nil)
        } catch {
            result(FlutterError(
                code: "SOUND_LOAD_FAILED",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    private func handlePlayTapSound(result: @escaping FlutterResult) {
        debugPrint("MetronomePlugin: playTapSound")
        audioEngine?.playTapSound()
        result(nil)
    }

    private func handleDispose(result: @escaping FlutterResult) {
        debugPrint("MetronomePlugin: handleDispose")
        audioEngine?.dispose()
        audioEngine = nil
        result(nil)
    }

    // MARK: - Event Sending

    private func sendBeatEvent(beat: Int, isAccent: Bool) {
        guard let eventSink = eventSink else { return }

        let event: [String: Any] = [
            "type": "beat",
            "beat": beat,
            "isAccent": isAccent
        ]
        eventSink(event)
    }

    private func sendSubdivisionEvent(subBeat: Int, isMainBeat: Bool) {
        guard let eventSink = eventSink else { return }

        let event: [String: Any] = [
            "type": "subdivision",
            "subBeat": subBeat,
            "isMainBeat": isMainBeat
        ]
        eventSink(event)
    }
}

// MARK: - FlutterStreamHandler

extension MetronomePlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        debugPrint("MetronomePlugin: onListen")
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        debugPrint("MetronomePlugin: onCancel")
        self.eventSink = nil
        return nil
    }
}
