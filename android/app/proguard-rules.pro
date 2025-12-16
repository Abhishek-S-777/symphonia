# Symphonia ProGuard Rules

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep local notifications
-keep class com.dexterous.** { *; }

# Keep vibration plugin
-keep class com.benjamindean.** { *; }

# Keep Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep Room/SQLite (Drift)
-keep class * extends androidx.room.RoomDatabase { *; }

# Keep model classes
-keep class com.symphonia.app.** { *; }
