import java.util.Base64
import java.io.File
import java.nio.file.Files

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreBase64: String? = System.getenv("KEYSTORE_BASE64")
val keystorePath: String? = System.getenv("KEYSTORE_PATH")
val releaseKeystore = if (keystorePath != null) File(keystorePath) else File("${project.buildDir}/cargolink_keystore.jks")
if (keystoreBase64 != null) {
    releaseKeystore.parentFile.mkdirs()
    Files.write(releaseKeystore.toPath(), Base64.getDecoder().decode(keystoreBase64))
}
val hasReleaseKeystore = releaseKeystore.exists()

android {
    namespace = "com.cargolink.dz.cargolink"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cargolink.dz.cargolink"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.create("release").apply {
                    storeFile = releaseKeystore
                    storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "changeme"
                    keyAlias = System.getenv("KEYSTORE_KEY_ALIAS") ?: "cargolink"
                    keyPassword = System.getenv("KEY_PASSWORD") ?: "changeme"
                }
            } else {
                // No keystore supplied (CI secrets missing or local dev): fall back to debug signing.
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
