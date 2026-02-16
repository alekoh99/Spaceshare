# Suppress all warnings for missing optional dependencies
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.stripe.android.**

# Keep all Stripe classes
-keep class com.stripe.android.** { *; }
-keep interface com.stripe.android.** { *; }

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }
-keep interface com.reactnativestripesdk.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }

# Keep Google Sign In
-keep class com.google.android.gms.auth.** { *; }

# Keep AdMob
-keep class com.google.android.gms.ads.** { *; }

# Keep Kotlin metadata and annotations
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep all generic types
-keepclassmembers class * {
    *** *(...);
}

# Keep enums
-keep enum * { *; }
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep interfaces
-keep interface * { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep View constructors for inflation
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

# Keep View subclasses
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep Activity subclasses
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.Fragment
-keep public class * extends androidx.fragment.app.Fragment

# Keep R class members
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable implementations
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep all public and protected members
-keepclassmembers public class * {
    public *;
    protected *;
}

# Keep Nimbus JOSE+JWT library classes
-keep class com.nimbusds.jose.** { *; }
-keep interface com.nimbusds.jose.** { *; }
-keep class com.nimbusds.jwt.** { *; }
-keep interface com.nimbusds.jwt.** { *; }
-keep class com.nimbusds.oauth2.** { *; }
-keep interface com.nimbusds.oauth2.** { *; }

# Keep BouncyCastle for crypto operations
-keep class org.bouncycastle.** { *; }
-keep interface org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Keep Tink crypto library
-keep class com.google.crypto.tink.** { *; }
-keep interface com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Keep OkHttp classes required by gRPC
-keep class com.squareup.okhttp.** { *; }
-keep interface com.squareup.okhttp.** { *; }
-dontwarn com.squareup.okhttp.**

# Keep gRPC classes
-keep class io.grpc.** { *; }
-keep interface io.grpc.** { *; }
-dontwarn io.grpc.**

# Keep Guava reflection classes
-keep class com.google.common.reflect.** { *; }
-keep interface com.google.common.reflect.** { *; }
-dontwarn com.google.common.reflect.**

# Keep Java reflection classes that are often minified
-keep class java.lang.reflect.AnnotatedType
-keep class java.lang.reflect.AnnotatedArrayType
-keep class java.lang.reflect.AnnotatedParameterizedType
-keep class java.lang.reflect.AnnotatedTypeVariable
-keep class java.lang.reflect.AnnotatedWildcardType
-dontwarn java.lang.reflect.AnnotatedType
