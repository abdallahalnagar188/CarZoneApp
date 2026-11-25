import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

val allowDebugSignedRelease = System.getenv("ALLOW_DEBUG_SIGNED_RELEASE") == "true"

// Fail early, before any task runs, when a release (apk, appbundle, Shorebird) is built
// without the upload key (GAP-056).
val buildsRelease = gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
if (buildsRelease && keystoreProperties.isEmpty && !allowDebugSignedRelease) {
    throw GradleException(
        "Release build without android/key.properties: the app would be signed with the debug key. " +
            "Provide key.properties and the upload keystore (CI: ANDROID_* secrets), or set " +
            "ALLOW_DEBUG_SIGNED_RELEASE=true for a local test build that is never distributed."
    )
}

android {
    namespace = "com.alnagar.washup"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.alnagar.washup"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // GAP-056: a release is always signed with the upload key from
            // android/key.properties. Without it the build fails (check above) instead
            // of silently producing a debug-signed app that Play and later updates
            // reject. For a local test of a release build only, set
            // ALLOW_DEBUG_SIGNED_RELEASE=true to sign it with the debug key.
            signingConfig = signingConfigs.getByName(
                if (keystoreProperties.isEmpty && allowDebugSignedRelease) "debug" else "release"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
