# Release builds shrink by default. shared_preferences 2.5 calls Kotlin
# suspend methods through JNI and looks them up by the original type name.
# If R8 renames kotlin.coroutines.Continuation, getAll no longer matches
# and the first read throws NoSuchMethodError.
-keep,includedescriptorclasses class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
