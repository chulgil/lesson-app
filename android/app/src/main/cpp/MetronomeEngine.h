#ifndef METRONOME_ENGINE_H
#define METRONOME_ENGINE_H

#include <oboe/Oboe.h>
#include <atomic>
#include <vector>
#include <mutex>
#include <thread>
#include <chrono>
#include <functional>

/**
 * Beat types for accent patterns.
 */
enum class BeatType {
    STRONG,
    MEDIUM,
    WEAK
};

/**
 * Callback types for beat events.
 */
using BeatCallback = std::function<void(int beat, bool isAccent)>;
using SubdivisionCallback = std::function<void(int subBeat, bool isMainBeat)>;

/**
 * High-precision metronome engine using Oboe for low-latency audio.
 *
 * Uses a callback-based audio stream for sample-accurate timing.
 * Similar to iOS AVAudioEngine approach but with Oboe's performance mode.
 */
class MetronomeEngine : public oboe::AudioStreamDataCallback {
public:
    MetronomeEngine();
    ~MetronomeEngine();

    // Initialization
    bool init(int bpm, int beatsPerMeasure, const std::string& accentPattern,
              int subdivision, const std::vector<bool>& soundPattern);

    // Sound loading (from raw PCM data)
    void loadSounds(const std::vector<int16_t>& strongSound,
                    const std::vector<int16_t>& mediumSound,
                    const std::vector<int16_t>& weakSound);

    // Playback control
    bool start();
    void stop();
    bool isPlaying() const { return mIsPlaying.load(); }

    // Settings
    void setBpm(int bpm);
    void setBeatsPerMeasure(int beats);
    void setAccentPattern(const std::string& pattern);
    void setSubdivision(int subdivision);
    void setSoundPattern(const std::vector<bool>& pattern);

    // Tap sound (for BPM tapping)
    void playTapSound();

    // Callbacks
    void setBeatCallback(BeatCallback callback);
    void setSubdivisionCallback(SubdivisionCallback callback);

    // Cleanup
    void dispose();

    // Oboe callback
    oboe::DataCallbackResult onAudioReady(
        oboe::AudioStream* stream,
        void* audioData,
        int32_t numFrames) override;

private:
    // Audio stream
    std::shared_ptr<oboe::AudioStream> mStream;
    static constexpr int32_t kSampleRate = 44100;
    static constexpr int32_t kChannelCount = 2;

    // Sound buffers (stereo PCM)
    std::vector<int16_t> mStrongBuffer;
    std::vector<int16_t> mMediumBuffer;
    std::vector<int16_t> mWeakBuffer;

    // Playback state
    std::atomic<bool> mIsPlaying{false};
    std::atomic<int> mBpm{120};
    std::atomic<int> mBeatsPerMeasure{4};
    std::atomic<int> mSubdivision{1};
    std::string mAccentPattern{"firstBeatOnly"};
    std::vector<bool> mSoundPattern{true};
    std::mutex mMutex;

    // Beat tracking
    int mCurrentBeat{0};
    int mCurrentSubBeat{0};
    int64_t mSamplesUntilNextBeat{0};
    int64_t mCurrentSamplePosition{0};

    // Sound playback tracking
    const int16_t* mCurrentPlayingBuffer{nullptr};
    size_t mCurrentPlayingPosition{0};
    size_t mCurrentPlayingLength{0};

    // Tap sound
    std::atomic<bool> mPlayTapSound{false};
    const int16_t* mTapSoundBuffer{nullptr};
    size_t mTapSoundPosition{0};
    size_t mTapSoundLength{0};

    // Callbacks
    BeatCallback mBeatCallback;
    SubdivisionCallback mSubdivisionCallback;

    // UI callback thread (for smooth Flutter callbacks)
    std::atomic<bool> mUiCallbackRunning{false};
    std::thread mUiCallbackThread;
    void uiCallbackLoop();

    // Helper methods
    int64_t calculateSamplesPerSubdivision() const;
    BeatType getBeatType(int beat) const;
    const int16_t* selectBuffer(int beat, int subBeat, BeatType beatType) const;
    size_t selectBufferLength(int beat, int subBeat, BeatType beatType) const;
    void advanceBeat();
    void notifyBeatCallbacks();
};

#endif // METRONOME_ENGINE_H
