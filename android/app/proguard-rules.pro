# Complete ProGuard rules for android/app/proguard-rules.pro

# Keep all Razorpay classes and suppress warnings
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep ProGuard annotations - This is crucial for the error you're seeing
-dontwarn proguard.annotation.**
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Keep classes annotated with ProGuard annotations
-keep @proguard.annotation.Keep class * { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
    @proguard.annotation.KeepClassMembers *;
}

# Google Play Core Library rules (NEW - to fix the current error)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter Play Store Split Application
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Additional Razorpay specific rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Razorpay payment callbacks
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# General Android rules
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson rules (if using JSON)
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# Additional safety rules to prevent over-optimization
-dontwarn com.google.android.play.**
-dontnote com.google.android.play.**