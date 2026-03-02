# Keep Oboe metronome JNI callback methods
-keep class app.lessonaza.audio.OboeMetronomeEngine {
    void onBeatCallback(int, boolean);
    void onSubdivisionCallback(int, boolean);
}

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
