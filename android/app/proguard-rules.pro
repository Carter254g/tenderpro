# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep model classes for JSON serialisation
-keep class com.tenderpro.tenderpro_ai.** { *; }

# OkHttp / http package
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
