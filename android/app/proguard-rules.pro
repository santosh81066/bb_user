# Complete ProGuard rules for Flutter app with Razorpay, Firebase, and Facebook integration

# ================================
# RAZORPAY PAYMENT GATEWAY RULES
# ================================
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Razorpay payment callbacks and attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Razorpay payment callbacks
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# ================================
# PROGUARD ANNOTATIONS
# ================================
-dontwarn proguard.annotation.**
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Keep classes annotated with ProGuard annotations
-keep @proguard.annotation.Keep class * { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
    @proguard.annotation.KeepClassMembers *;
}

# ================================
# GOOGLE PLAY CORE LIBRARY
# ================================
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.**
-dontnote com.google.android.play.**

# ================================
# FLUTTER FRAMEWORK
# ================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Play Store Split Application
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# ================================
# FIREBASE
# ================================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepnames class com.fasterxml.jackson.** { *; }
-keepnames class javax.servlet.** { *; }
-keepnames class org.ietf.jgss.** { *; }
-dontwarn org.apache.**
-dontwarn org.w3c.dom.**

# Google Play Services
-keep class * extends java.util.ListResourceBundle {
    protected Object[][] getContents();
}
-keep public class com.google.android.gms.common.internal.safeparcel.SafeParcelable {
    public static final *** NULL;
}
-keepnames @com.google.android.gms.common.annotation.KeepName class *
-keepclassmembernames class * {
    @com.google.android.gms.common.annotation.KeepName *;
}

# ================================
# FACEBOOK SDK
# ================================
-keep class com.facebook.** { *; }
-keep interface com.facebook.** { *; }
-keepattributes Signature
-dontwarn com.facebook.**

# ================================
# ANDROID FRAMEWORK
# ================================
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# ================================
# JSON PROCESSING (GSON)
# ================================
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# ================================
# GENERAL OPTIMIZATION SAFETY
# ================================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod