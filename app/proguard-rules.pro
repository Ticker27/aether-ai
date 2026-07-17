# Aether — keep native engine bridge
-keep class com.aether.core.NativeCore { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
-dontwarn **
