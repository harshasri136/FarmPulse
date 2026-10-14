# Keep Just Audio
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.audiosession.** { *; }

# Keep ExoPlayer
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Keep Kotlin Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep Android Media
-keep class android.media.** { *; }

# Prevent stripping methods
-keepclassmembers class * {
    public *;
}

# Keep Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep constructors
-keepclassmembers class * {
    public <init>(...);
}
