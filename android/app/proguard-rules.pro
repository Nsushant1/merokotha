# MeroKotha release ProGuard/R8 rules.
# Referenced by android/app/build.gradle.kts. Minify is currently disabled,
# but these rules prevent R8 from breaking Google Sign-In / Firebase Auth
# if minify/shrink is ever enabled for release builds.

# Google Play Services / Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.client.** { *; }
-dontwarn com.google.android.gms.**

# Firebase Auth / Core
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.auth.internal.** { *; }
-dontwarn com.google.firebase.**

# Credential / OAuth helpers used via platform channels
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes *Annotation*
