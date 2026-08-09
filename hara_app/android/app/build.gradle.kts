import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadReleaseSigning(): Properties {
    val props = Properties()
    val envPath = System.getenv("ANDROID_KEYSTORE_PATH")
    if (!envPath.isNullOrBlank()) {
        props["storeFile"] = envPath
        props["storePassword"] = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: ""
        props["keyAlias"] = System.getenv("ANDROID_KEY_ALIAS") ?: ""
        props["keyPassword"] = System.getenv("ANDROID_KEY_PASSWORD") ?: ""
        return props
    }
    val localKeystore = File(rootProject.projectDir.parentFile.parentFile, "keystore/hara-release.jks")
    val localPassFile = File(rootProject.projectDir.parentFile.parentFile, "keystore/password.txt")
    if (localKeystore.exists() && localPassFile.exists()) {
        props["storeFile"] = localKeystore.absolutePath
        props["storePassword"] = localPassFile.readText().trim()
        props["keyAlias"] = "hara"
        props["keyPassword"] = localPassFile.readText().trim()
    }
    return props
}

android {
    namespace = "ps.hara.hara_app"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ps.hara.hara_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val props = loadReleaseSigning()
            if (props.containsKey("storeFile")) {
                storeFile = File(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Signed with the release keystore when available (env vars from CI or local keystore/ folder).
            // Falls back to debug signing otherwise so builds never break.
            val props = loadReleaseSigning()
            signingConfig = if (props.containsKey("storeFile")) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
