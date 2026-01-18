import AVFoundation

/// AVAudioEngine-based metronome for sample-accurate timing.
/// Uses scheduleBuffer(at:) for precise beat scheduling.
class MetronomeAudioEngine {

    // MARK: - Properties

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    private var strongBuffer: AVAudioPCMBuffer?
    private var mediumBuffer: AVAudioPCMBuffer?
    private var weakBuffer: AVAudioPCMBuffer?

    private var sampleRate: Double = 44100.0
    private var bpm: Int = 120
    private var beatsPerMeasure: Int = 4
    private var accentPattern: String = "firstBeatOnly"

    private var isRunning = false
    private var currentBeat: Int = 0
    private var beatsScheduled: Int = 0
    private var nextBeatSampleTime: Double = 0

    private let beatsToScheduleAhead = 4
    private let syncQueue = DispatchQueue(label: "com.lessonapp.metronome.sync")

    // Callback for beat events
    var onBeat: ((_ beat: Int, _ isAccent: Bool) -> Void)?

    // MARK: - Initialization

    init() {
        debugPrint("MetronomeAudioEngine: init")
    }

    deinit {
        debugPrint("MetronomeAudioEngine: deinit")
        stop()
    }

    // MARK: - Setup

    func setup(
        bpm: Int,
        beatsPerMeasure: Int,
        accentPattern: String,
        strongSoundPath: String,
        mediumSoundPath: String,
        weakSoundPath: String
    ) throws {
        debugPrint("MetronomeAudioEngine: setup started")
        debugPrint("  BPM: \(bpm), beatsPerMeasure: \(beatsPerMeasure)")
        debugPrint("  strongSound: \(strongSoundPath)")

        self.bpm = bpm
        self.beatsPerMeasure = beatsPerMeasure
        self.accentPattern = accentPattern

        // Setup audio engine
        try setupEngine()

        // Load sounds
        strongBuffer = try loadSound(assetPath: strongSoundPath)
        mediumBuffer = try loadSound(assetPath: mediumSoundPath)
        weakBuffer = try loadSound(assetPath: weakSoundPath)

        debugPrint("MetronomeAudioEngine: setup complete")
    }

    private func setupEngine() throws {
        debugPrint("MetronomeAudioEngine: setupEngine")

        // Attach player node
        engine.attach(player)

        // Get output format
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        sampleRate = outputFormat.sampleRate
        debugPrint("  Sample rate: \(sampleRate)")

        // Connect player to main mixer
        engine.connect(player, to: engine.mainMixerNode, format: outputFormat)

        // Prepare and start engine
        engine.prepare()
        try engine.start()

        debugPrint("MetronomeAudioEngine: engine started")
    }

    // MARK: - Sound Loading

    private func loadSound(assetPath: String) throws -> AVAudioPCMBuffer {
        debugPrint("MetronomeAudioEngine: loadSound - \(assetPath)")

        // Flutter assets are located in App.framework/flutter_assets/
        let flutterAssetsPath = "Frameworks/App.framework/flutter_assets"
        let fullPath = "\(flutterAssetsPath)/\(assetPath)"

        // Try to find the file
        guard let url = Bundle.main.url(forResource: fullPath, withExtension: nil) else {
            // Try alternate path without extension in resource name
            let pathWithoutExt = (fullPath as NSString).deletingPathExtension
            let ext = (fullPath as NSString).pathExtension

            if let altUrl = Bundle.main.url(forResource: pathWithoutExt, withExtension: ext) {
                return try loadSoundFromURL(altUrl)
            }

            debugPrint("MetronomeAudioEngine: Sound file not found at \(fullPath)")
            throw MetronomeError.soundNotFound(path: assetPath)
        }

        return try loadSoundFromURL(url)
    }

    private func loadSoundFromURL(_ url: URL) throws -> AVAudioPCMBuffer {
        debugPrint("MetronomeAudioEngine: Loading from \(url.path)")

        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw MetronomeError.bufferCreationFailed
        }

        try file.read(into: buffer)
        debugPrint("MetronomeAudioEngine: Loaded \(frameCount) frames")

        return buffer
    }

    // MARK: - Playback Control

    func start() {
        debugPrint("MetronomeAudioEngine: start")

        guard !isRunning else {
            debugPrint("MetronomeAudioEngine: already running")
            return
        }

        // Ensure engine is running
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                debugPrint("MetronomeAudioEngine: Failed to start engine - \(error)")
                return
            }
        }

        isRunning = true
        currentBeat = 0
        beatsScheduled = 0

        // Calculate initial sample time (start from current time + small offset)
        if let nodeTime = player.lastRenderTime,
           let playerTime = player.playerTime(forNodeTime: nodeTime) {
            nextBeatSampleTime = Double(playerTime.sampleTime) + sampleRate * 0.1 // 100ms offset
        } else {
            nextBeatSampleTime = 0
        }

        player.play()

        // Schedule initial beats
        syncQueue.async { [weak self] in
            self?.scheduleBeats()
        }

        debugPrint("MetronomeAudioEngine: started at \(bpm) BPM")
    }

    func stop() {
        debugPrint("MetronomeAudioEngine: stop")

        guard isRunning else { return }

        isRunning = false
        player.stop()

        debugPrint("MetronomeAudioEngine: stopped")
    }

    // MARK: - Beat Scheduling

    private func scheduleBeats() {
        guard isRunning else { return }

        while beatsScheduled < beatsToScheduleAhead && isRunning {
            let beatTime = AVAudioTime(
                sampleTime: AVAudioFramePosition(nextBeatSampleTime),
                atRate: sampleRate
            )

            // Select buffer based on beat and accent pattern
            currentBeat = (currentBeat % beatsPerMeasure) + 1
            let isAccent = isAccentBeat(currentBeat)
            let buffer = selectBuffer(forBeat: currentBeat, isAccent: isAccent)

            guard let buffer = buffer else {
                debugPrint("MetronomeAudioEngine: No buffer for beat \(currentBeat)")
                continue
            }

            // Capture current beat for callback
            let beatNumber = currentBeat

            // Schedule buffer with completion handler
            player.scheduleBuffer(buffer, at: beatTime, options: []) { [weak self] in
                guard let self = self, self.isRunning else { return }

                // Send beat event on main thread
                DispatchQueue.main.async {
                    self.onBeat?(beatNumber, isAccent)
                }

                // Schedule more beats
                self.syncQueue.async {
                    self.beatsScheduled -= 1
                    self.scheduleBeats()
                }
            }

            // Calculate next beat time
            let samplesPerBeat = sampleRate * 60.0 / Double(bpm)
            nextBeatSampleTime += samplesPerBeat
            beatsScheduled += 1
        }
    }

    private func isAccentBeat(_ beat: Int) -> Bool {
        switch accentPattern {
        case "firstBeatOnly", "strongMediumWeak":
            return beat == 1
        case "uniform":
            return false
        default:
            return beat == 1
        }
    }

    private func selectBuffer(forBeat beat: Int, isAccent: Bool) -> AVAudioPCMBuffer? {
        if isAccent {
            return strongBuffer
        }

        // For non-accent beats, use medium or weak based on pattern
        switch accentPattern {
        case "strongMediumWeak":
            // Could implement more complex logic here
            return weakBuffer
        default:
            return weakBuffer
        }
    }

    // MARK: - Settings Update

    func setBpm(_ newBpm: Int) {
        syncQueue.async { [weak self] in
            self?.bpm = newBpm
            debugPrint("MetronomeAudioEngine: BPM set to \(newBpm)")
        }
    }

    func setBeatsPerMeasure(_ beats: Int) {
        syncQueue.async { [weak self] in
            self?.beatsPerMeasure = beats
            debugPrint("MetronomeAudioEngine: beatsPerMeasure set to \(beats)")
        }
    }

    func setAccentPattern(_ pattern: String) {
        syncQueue.async { [weak self] in
            self?.accentPattern = pattern
            debugPrint("MetronomeAudioEngine: accentPattern set to \(pattern)")
        }
    }

    func updateSounds(
        strongPath: String,
        mediumPath: String,
        weakPath: String
    ) throws {
        debugPrint("MetronomeAudioEngine: updateSounds")
        strongBuffer = try loadSound(assetPath: strongPath)
        mediumBuffer = try loadSound(assetPath: mediumPath)
        weakBuffer = try loadSound(assetPath: weakPath)
    }

    // MARK: - Tap Sound

    func playTapSound() {
        guard let buffer = weakBuffer else { return }

        // Play immediately
        player.scheduleBuffer(buffer, at: nil, options: [])

        if !player.isPlaying {
            player.play()
        }
    }

    // MARK: - Cleanup

    func dispose() {
        debugPrint("MetronomeAudioEngine: dispose")
        stop()
        engine.stop()
        strongBuffer = nil
        mediumBuffer = nil
        weakBuffer = nil
    }
}

// MARK: - Errors

enum MetronomeError: Error, LocalizedError {
    case soundNotFound(path: String)
    case bufferCreationFailed
    case engineStartFailed

    var errorDescription: String? {
        switch self {
        case .soundNotFound(let path):
            return "Sound file not found: \(path)"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .engineStartFailed:
            return "Failed to start audio engine"
        }
    }
}
