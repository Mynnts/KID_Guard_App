# Add project specific ProGuard rules here.
# Keep Flutter framework
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Firebase SDK
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Firestore models - keep data class members
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep SecurityService class (our security detection must not be obfuscated)
-keep class com.seniorproject.kid_guard.SecurityService { *; }
-keep class com.seniorproject.kid_guard.SecurityLogger { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep R class members
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Don't warn about missing classes
-dontwarn kotlin.**
-dontwarn kotlinx.**
-dontwarn org.jetbrains.annotations.**

# Keep annotation classes
-keep class androidx.annotation.** { *; }
-keep class javax.annotation.** { *; }

# Optimization settings
-optimizationpasses 5
-allowaccessmodification
-repackageclasses ''

# Remove logging in release builds (optional security measure)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}

# Keep Workmanager classes
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**
