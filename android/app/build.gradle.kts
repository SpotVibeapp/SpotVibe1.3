import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "app.spotvibe"
    compileSdk = 36
    ndkVersion = "27.3.13750724"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "app.spotvibe"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Attach the upload key only when it exists. The verification task
            // below stops release builds clearly when it does not.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Debug builds do not need a Play upload key. Release builds still fail clearly
// unless android/key.properties contains a real upload-keystore configuration.
val verifyReleaseSigning = tasks.register("verifyReleaseSigning") {
    group = "verification"
    description = "Verifies that the Android upload keystore is configured for release builds."

    doLast {
        val required = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
        val missing = required.filter { keystoreProperties.getProperty(it).isNullOrBlank() }

        if (!keystorePropertiesFile.exists() || missing.isNotEmpty()) {
            val missingHint =
                if (missing.isEmpty()) "" else " Missing: ${missing.joinToString()}."

            throw GradleException(
                "Release signing is not configured. Create android/key.properties " +
                    "with your upload keystore before building a release artifact " +
                    "(flutter build appbundle).$missingHint"
            )
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild" || name == "assembleRelease" || name == "bundleRelease") {
        dependsOn(verifyReleaseSigning)
    }
}

flutter {
    source = "../.."
}