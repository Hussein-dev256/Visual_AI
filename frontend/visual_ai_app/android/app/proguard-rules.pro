# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Image processing
-keep class com.example.visual_ai_app.** { *; }
-keepclassmembers class * {
    native <methods>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep your application classes that will be accessed through reflection
-keep class com.example.visual_ai_app.** { *; }

# Keep Kotlin Metadata
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn sun.misc.**
-keep class kotlin.** { *; }
-keep class org.jetbrains.** { *; }

# Keep Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep Parcelables
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
} 