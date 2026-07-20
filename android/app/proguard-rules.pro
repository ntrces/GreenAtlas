# Keep ARCore/Sceneform classes
-keep class com.google.ar.sceneform.** { *; }
-keep class com.google.ar.core.** { *; }
-keepclassmembers class com.google.ar.sceneform.** { *; }
-keepclassmembers class com.google.ar.core.** { *; }

# Keep Android desugar runtime
-keep class com.google.devtools.build.android.desugar.runtime.** { *; }

# Keep AndroidIntentPlus
-keep class dev.fluttercommunity.plus.androidintent.** { *; }

# Keep Flutter native code
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress R8 missing class warnings
-dontwarn com.google.android.play.core.**
-dontwarn com.google.ar.sceneform.**
-dontwarn com.google.devtools.build.android.desugar.runtime.**
