# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Sceneform rules
-dontwarn com.google.ar.sceneform.**
-keep class com.google.ar.sceneform.** { *; }

# TensorFlow Lite rules
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }

# Play Core rules (Flutter embedding)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Ignore desugar throwable extension
-dontwarn com.google.devtools.build.android.desugar.runtime.**
