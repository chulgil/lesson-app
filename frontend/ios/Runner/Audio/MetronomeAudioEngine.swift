import AVFoundation

// MARK: - Timing Module

/// Centralized timing calculations for metronome.
/// Provides consistent timing logic for both audio scheduling and UI callbacks.
struct MetronomeTiming {
    let bpm: Int
    let subdivision: Int
    let beatsPerMeasure: Int
    let sampleRate: Double

    /// Seconds per main beat (quarter note at given BPM).
    var secondsPerBeat: Double {
        60.0 / Double(bpm)
    }

    /// Seconds per subdivision tick.
    var secondsPerSubdivision: Double {
        secondsPerBeat / Double(subdivision)
    }

    /// Samples per main beat.
    var samplesPerBeat: Double {
        sampleRate * secondsPerBeat
    }

    /// Samples per subdivision tick.
    var samplesPerSubdivision: Double {
        samplesPerBeat / Double(subdivision)
    }

    /// Create timing configuration.
    static func create(bpm: Int, subdivision: Int, beatsPerMeasure: Int, sampleRate: Double = 44100.0) -> MetronomeTiming {
        return MetronomeTiming(bpm: bpm, subdivision: subdivision, beatsPerMeasure: beatsPerMeasure, sampleRate: sampleRate)
    }
}

// MARK: - Animation Callback Protocol

/// Protocol for metronome animation callbacks.
/// Implement this to provide custom animation behavior.
protocol MetronomeAnimationDelegate: AnyObject {
    /// Called on every subdivision tick (for paw animation).
    func onSubdivisionTick(subdivisionIndex: Int, isMainBeat: Bool, isSound: Bool)

    /// Called on main beats only (for beat counter).
    func onBeatTick(beat: Int, isAccent: Bool)
}

// MARK: - UI Callback Manager

/// Timer-based UI callback manager for metronome animations.
/// Uses a high-precision timer independent of audio scheduling.
/// This ensures animations fire correctly even for rest beats.
class MetronomeUICallback {
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.lessonapp.metronome.ui", qos: .userInteractive)

    private var timing: MetronomeTiming
    private var soundPattern: [Bool]
    private var accentPattern: String

    private var currentSubdivisionIndex: Int = 0
    private var isRunning: Bool = false

    weak var delegate: MetronomeAnimationDelegate?

    init(timing: MetronomeTiming, soundPattern: [Bool], accentPattern: String) {
        self.timing = timing
        self.soundPattern = soundPattern.isEmpty ? [true] : soundPattern
        self.accentPattern = accentPattern
    }

    func updateTiming(_ newTiming: MetronomeTiming) {
        let wasRunning = isRunning
        if wasRunning { stop() }
        timing = newTiming
        if wasRunning { start() }
    }

    func updateSoundPattern(_ pattern: [Bool]) {
        soundPattern = pattern.isEmpty ? [true] : pattern
    }

    func updateAccentPattern(_ pattern: String) {
        accentPattern = pattern
    }

    func start() {
        guard !isRunning else { return }

        isRunning = true
        currentSubdivisionIndex = 0

        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        let intervalNanoseconds = UInt64(timing.secondsPerSubdivision * 1_000_000_000)
        timer?.schedule(deadline: .now(), repeating: .nanoseconds(Int(intervalNanoseconds)), leeway: .milliseconds(1))

        timer?.setEventHandler { [weak self] in
            self?.tick()
        }

        timer?.resume()
        debugPrint("MetronomeUICallback: started with interval \(timing.secondsPerSubdivision)s")
    }

    func stop() {
        guard isRunning else { return }

        isRunning = false
        timer?.cancel()
        timer = nil
        currentSubdivisionIndex = 0
        debugPrint("MetronomeUICallback: stopped")
    }

    private func tick() {
        guard isRunning else { return }

        let subdivisionInBeat = currentSubdivisionIndex % timing.subdivision
        let beatIndex = (currentSubdivisionIndex / timing.subdivision) % timing.beatsPerMeasure
        let beat = beatIndex + 1

        let isMainBeat = subdivisionInBeat == 0
        let isSound = soundPattern[subdivisionInBeat % soundPattern.count]
        let isAccent = isMainBeat && isAccentBeat(beat)

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.delegate?.onSubdivisionTick(subdivisionIndex: subdivisionInBeat, isMainBeat: isMainBeat, isSound: isSound)
            if isMainBeat {
                self.delegate?.onBeatTick(beat: beat, isAccent: isAccent)
            }
        }

        currentSubdivisionIndex += 1
    }

    private func isAccentBeat(_ beat: Int) -> Bool {
        switch accentPattern {
        case "firstBeatOnly", "strongMediumWeak": return beat == 1
        case "uniform": return false
        default: return beat == 1
        }
    }

    deinit { stop() }
}

// MARK: - Audio Engine

/// AVAudioEngine-based metronome for sample-accurate timing.
/// Uses scheduleBuffer(at:) for precise beat scheduling.
/// UI callbacks are handled by MetronomeUICallback for consistent animation timing.
class MetronomeAudioEngine: MetronomeAnimationDelegate {

    // MARK: - Properties

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    private var strongBuffer: AVAudioPCMBuffer?
    private var mediumBuffer: AVAudioPCMBuffer?
    private var weakBuffer: AVAudioPCMBuffer?

    private var playerFormat: AVAudioFormat?  // Format used for player connection
    private var sampleRate: Double = 44100.0
    private var bpm: Int = 120
    private var beatsPerMeasure: Int = 4
    private var accentPattern: String = "firstBeatOnly"
    private var subdivision: Int = 1  // 1=quarter, 2=eighth, 3=triplet, 4=sixteenth
    private var soundPattern: [Bool] = [true]  // Which sub-beats should sound (true=sound, false=rest)

    private var isRunning = false
    private var currentBeat: Int = 0
    private var currentSubBeat: Int = 0  // 0 to subdivision-1
    private var beatsScheduled: Int = 0
    private var nextBeatSampleTime: Double = 0

    private let beatsToScheduleAhead = 4
    private let syncQueue = DispatchQueue(label: "com.lessonapp.metronome.sync")

    // UI callback manager (timer-based, independent of audio scheduling)
    private var uiCallback: MetronomeUICallback?

    // Callback for beat events
    var onBeat: ((_ beat: Int, _ isAccent: Bool) -> Void)?

    // Callback for subdivision events (for UI animation)
    var onSubdivision: ((_ subBeat: Int, _ isMainBeat: Bool) -> Void)?

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
        subdivision: Int,
        strongSoundPath: String,
        mediumSoundPath: String,
        weakSoundPath: String
    ) throws {
        debugPrint("MetronomeAudioEngine: setup started")
        debugPrint("  BPM: \(bpm), beatsPerMeasure: \(beatsPerMeasure), subdivision: \(subdivision)")
        debugPrint("  strongSound: \(strongSoundPath)")

        self.bpm = bpm
        self.beatsPerMeasure = beatsPerMeasure
        self.accentPattern = accentPattern
        self.subdivision = subdivision

        // Load sounds first to get the format
        strongBuffer = try loadSound(assetPath: strongSoundPath)
        mediumBuffer = try loadSound(assetPath: mediumSoundPath)
        weakBuffer = try loadSound(assetPath: weakSoundPath)

        // Get the format from loaded sounds
        guard let format = strongBuffer?.format else {
            throw MetronomeError.bufferCreationFailed
        }
        playerFormat = format
        debugPrint("MetronomeAudioEngine: Sound format - channels: \(format.channelCount), sampleRate: \(format.sampleRate)")

        // Setup audio engine with the sound format
        try setupEngine(withFormat: format)

        // Setup UI callback manager
        setupUICallback()

        debugPrint("MetronomeAudioEngine: setup complete")
    }

    private func setupUICallback() {
        let timing = MetronomeTiming.create(
            bpm: bpm,
            subdivision: subdivision,
            beatsPerMeasure: beatsPerMeasure,
            sampleRate: sampleRate
        )
        uiCallback = MetronomeUICallback(timing: timing, soundPattern: soundPattern, accentPattern: accentPattern)
        uiCallback?.delegate = self
        debugPrint("MetronomeAudioEngine: UI callback manager initialized")
    }

    private func setupEngine(withFormat format: AVAudioFormat) throws {
        debugPrint("MetronomeAudioEngine: setupEngine with format - channels: \(format.channelCount), sampleRate: \(format.sampleRate)")

        // Attach player node
        engine.attach(player)

        // Use the sound file's sample rate
        sampleRate = format.sampleRate
        debugPrint("  Sample rate: \(sampleRate)")

        // Connect player to main mixer with the sound file's format
        engine.connect(player, to: engine.mainMixerNode, format: format)

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
                debugPrint("MetronomeAudioEngine: engine.start() succeeded")
            } catch {
                debugPrint("MetronomeAudioEngine: Failed to start engine - \(error)")
                return
            }
        }

        isRunning = true
        currentBeat = 1  // Start at beat 1 (not 0) for correct accent detection
        currentSubBeat = 0
        beatsScheduled = 0

        debugPrint("MetronomeAudioEngine: subdivision=\(subdivision), soundPattern=\(soundPattern)")

        // Start player first
        player.play()
        debugPrint("MetronomeAudioEngine: player.play() called")

        // Start UI callback timer (handles all animation callbacks including rests)
        uiCallback?.start()

        // Schedule initial audio beats - calculate timing AFTER player starts
        syncQueue.async { [weak self] in
            guard let self = self else { return }

            // Calculate initial sample time AFTER player has started
            if let nodeTime = self.player.lastRenderTime,
               let playerTime = self.player.playerTime(forNodeTime: nodeTime) {
                self.nextBeatSampleTime = Double(playerTime.sampleTime) + self.sampleRate * 0.05 // 50ms offset
                debugPrint("MetronomeAudioEngine: nextBeatSampleTime from playerTime = \(self.nextBeatSampleTime)")
            } else {
                self.nextBeatSampleTime = self.sampleRate * 0.05  // 50ms fallback
                debugPrint("MetronomeAudioEngine: nextBeatSampleTime fallback = \(self.nextBeatSampleTime)")
            }

            debugPrint("MetronomeAudioEngine: calling scheduleBeats()")
            self.scheduleBeats()
            debugPrint("MetronomeAudioEngine: scheduleBeats() completed")
        }

        debugPrint("MetronomeAudioEngine: started at \(bpm) BPM")
    }

    func stop() {
        debugPrint("MetronomeAudioEngine: stop")

        guard isRunning else { return }

        isRunning = false
        uiCallback?.stop()  // Stop UI callbacks
        player.stop()

        debugPrint("MetronomeAudioEngine: stopped")
    }

    // MARK: - Beat Scheduling

    private func scheduleBeats() {
        guard isRunning else {
            debugPrint("MetronomeAudioEngine.scheduleBeats: not running, returning")
            return
        }

        debugPrint("MetronomeAudioEngine.scheduleBeats: beatsScheduled=\(beatsScheduled), toScheduleAhead=\(beatsToScheduleAhead)")

        var loopCount = 0
        let maxLoops = 100  // Safety limit to prevent infinite loops

        while beatsScheduled < beatsToScheduleAhead && isRunning && loopCount < maxLoops {
            loopCount += 1

            let beatTime = AVAudioTime(
                sampleTime: AVAudioFramePosition(nextBeatSampleTime),
                atRate: sampleRate
            )

            // Advance sub-beat first
            currentSubBeat += 1
            if currentSubBeat > subdivision {
                currentSubBeat = 1
                currentBeat = (currentBeat % beatsPerMeasure) + 1
            }

            // First sub-beat of each main beat
            let isMainBeat = currentSubBeat == 1
            let isAccent = isMainBeat && isAccentBeat(currentBeat)
            let buffer = selectBuffer(forBeat: currentBeat, subBeat: currentSubBeat, isAccent: isAccent)

            // Capture current beat for callback
            let beatNumber = currentBeat
            let subBeatNumber = currentSubBeat

            // Calculate next sub-beat time
            let samplesPerBeat = sampleRate * 60.0 / Double(bpm)
            let samplesPerSubBeat = samplesPerBeat / Double(subdivision)

            // Advance timing
            nextBeatSampleTime += samplesPerSubBeat

            if let buffer = buffer {
                // Schedule sound buffer with completion handler
                // Note: UI callbacks are handled by MetronomeUICallback timer
                player.scheduleBuffer(buffer, at: beatTime, options: []) { [weak self] in
                    guard let self = self, self.isRunning else { return }

                    // Schedule more beats
                    self.syncQueue.async {
                        self.beatsScheduled -= 1
                        self.scheduleBeats()
                    }
                }
                beatsScheduled += 1
            }
            // Rest beats: no audio scheduling needed
            // UI callbacks are handled by MetronomeUICallback timer
        }

        if loopCount >= maxLoops {
            debugPrint("MetronomeAudioEngine.scheduleBeats: WARNING - hit max loop limit!")
        }

        debugPrint("MetronomeAudioEngine.scheduleBeats: done, beatsScheduled=\(beatsScheduled)")
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

    private func selectBuffer(forBeat beat: Int, subBeat: Int, isAccent: Bool) -> AVAudioPCMBuffer? {
        // Check if this sub-beat should play sound (based on soundPattern)
        // subBeat is 1-indexed, soundPattern is 0-indexed
        let patternIndex = (subBeat - 1) % soundPattern.count
        if !soundPattern[patternIndex] {
            // This is a rest - no sound
            return nil
        }

        // Uniform pattern: all beats use medium (same intensity)
        if accentPattern == "uniform" {
            // Main beat uses medium, sub-beats use weak
            return subBeat == 1 ? mediumBuffer : weakBuffer
        }

        // For accented patterns
        if isAccent && subBeat == 1 {
            return strongBuffer
        }

        // For main beats (first sub-beat)
        if subBeat == 1 {
            switch accentPattern {
            case "strongMediumWeak":
                // Beat 3 in 4/4 could use medium
                return weakBuffer
            default:
                return weakBuffer
            }
        }

        // For sub-beats (not the first one), always use weak
        return weakBuffer
    }

    // MARK: - Settings Update

    func setBpm(_ newBpm: Int) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.bpm = newBpm

            // Update UI callback timing
            let timing = MetronomeTiming.create(
                bpm: newBpm,
                subdivision: self.subdivision,
                beatsPerMeasure: self.beatsPerMeasure,
                sampleRate: self.sampleRate
            )
            self.uiCallback?.updateTiming(timing)

            debugPrint("MetronomeAudioEngine: BPM set to \(newBpm)")
        }
    }

    func setBeatsPerMeasure(_ beats: Int) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.beatsPerMeasure = beats

            // Update UI callback timing
            let timing = MetronomeTiming.create(
                bpm: self.bpm,
                subdivision: self.subdivision,
                beatsPerMeasure: beats,
                sampleRate: self.sampleRate
            )
            self.uiCallback?.updateTiming(timing)

            debugPrint("MetronomeAudioEngine: beatsPerMeasure set to \(beats)")
        }
    }

    func setAccentPattern(_ pattern: String) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.accentPattern = pattern
            self.uiCallback?.updateAccentPattern(pattern)
            debugPrint("MetronomeAudioEngine: accentPattern set to \(pattern)")
        }
    }

    func setSubdivision(_ newSubdivision: Int) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.subdivision = newSubdivision

            // Update UI callback timing
            let timing = MetronomeTiming.create(
                bpm: self.bpm,
                subdivision: newSubdivision,
                beatsPerMeasure: self.beatsPerMeasure,
                sampleRate: self.sampleRate
            )
            self.uiCallback?.updateTiming(timing)

            debugPrint("MetronomeAudioEngine: subdivision set to \(newSubdivision)")
        }
    }

    func setSoundPattern(_ pattern: [Bool]) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            self.soundPattern = pattern.isEmpty ? [true] : pattern
            self.uiCallback?.updateSoundPattern(self.soundPattern)
            debugPrint("MetronomeAudioEngine: soundPattern set to \(pattern)")
        }
    }

    // MARK: - MetronomeAnimationDelegate

    func onSubdivisionTick(subdivisionIndex: Int, isMainBeat: Bool, isSound: Bool) {
        // Forward to Flutter through the callback
        onSubdivision?(subdivisionIndex, isMainBeat)
    }

    func onBeatTick(beat: Int, isAccent: Bool) {
        // Forward to Flutter through the callback
        onBeat?(beat, isAccent)
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
