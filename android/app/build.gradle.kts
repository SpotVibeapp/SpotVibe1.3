import java.util.Base64
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.spotvibe"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // Android 8.0
        // Google Play requires new submissions to target Android 16 (API 36)
        // from 2026-08-31. Pin it so the build can never silently target lower.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AdMob application id baked into the manifest. Defaults to Google's
        // official TEST app id so debug builds and CI never risk a policy strike
        // from live ads, AND so a blank/typo'd property can never crash the app
        // at launch with "Missing application ID". Provide the real id via:
        //   -PadmobAppId=ca-app-pub-XXXXXXXX~YYYYYYYY
        //   or add `admobAppId=ca-app-pub-…~…` to android/gradle.properties
        // The id must be the "~" App ID, NOT the "/" ad-unit id.
        // Release builds FAIL while this is still the test id or a placeholder
        // (see verifyReleaseAdMobIds below); debug builds keep the test id.
        val admobAppIdProp = (project.findProperty("admobAppId") as String?)?.trim()
        val admobAppId = if (admobAppIdProp.isNullOrBlank()) {
            "ca-app-pub-3940256099942544~3347511713" // Google TEST app id
        } else {
            admobAppIdProp
        }
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    signingConfigs {
        create("release") {
            // Use safe casts so a missing key.properties doesn't crash the build.
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Only attach the upload key when it exists. The verification task
            // below fails *release* builds clearly when it does not. Do not
            // throw here: Gradle configures every build type for `flutter run`,
            // including a debug build that does not need release signing.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Release signing must fail loudly, but only when a release artifact is being
// built. `preReleaseBuild` is not part of `assembleDebug`, so this preserves
// normal device testing via `flutter run` without permitting unsigned releases.
val verifyReleaseSigning = tasks.register("verifyReleaseSigning") {
    group = "verification"
    description = "Verifies that the Android upload keystore is configured for release builds."

    doLast {
        val required = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
        val missing = required.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
        if (!keystorePropertiesFile.exists() || missing.isNotEmpty()) {
            val missingHint = if (missing.isEmpty()) "" else " Missing: ${missing.joinToString()}."
            throw GradleException(
                "Release signing is not configured. Create android/key.properties " +
                    "with your upload keystore before building a release artifact " +
                    "(flutter build appbundle).$missingHint"
            )
        }
    }
}

// ── AdMob ids must be real in release builds ─────────────────────────────
// Mirrors the iOS "Check iOS App IDs" build phase from PR #2 and
// lib/services/admob_ids.dart. A release APK/AAB must never ship Google's
// sample ids (publisher ca-app-pub-3940256099942544) or a template
// placeholder, for either the manifest app id (-PadmobAppId / gradle.properties)
// or the banner ad unit (--dart-define ADMOB_BANNER_ANDROID, which Flutter
// forwards to Gradle base64-encoded in the `dart-defines` property).
// Debug and profile builds are unaffected and keep the test ids.
val googleTestAdMobPublisher = "ca-app-pub-3940256099942544"

fun admobIdProblem(id: String?, appId: Boolean): String? {
    val value = id?.trim().orEmpty()
    if (value.isEmpty()) return "is not set"
    if (value.startsWith(googleTestAdMobPublisher)) return "is Google's sample/test id"
    val pattern = if (appId) Regex("^ca-app-pub-\\d{10,20}~\\d{6,20}$")
    else Regex("^ca-app-pub-\\d{10,20}/\\d{6,20}$")
    if (!pattern.matches(value)) return "is not a valid ${if (appId) "~ app id" else "/ ad unit id"} (placeholder?)"
    return null
}

fun dartDefines(): Map<String, String> {
    val raw = (project.findProperty("dart-defines") as String?).orEmpty()
    if (raw.isBlank()) return emptyMap()
    return raw.split(",").mapNotNull { encoded ->
        val decoded = try {
            String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        } catch (e: IllegalArgumentException) {
            return@mapNotNull null
        }
        val eq = decoded.indexOf('=')
        if (eq <= 0) null else decoded.substring(0, eq) to decoded.substring(eq + 1)
    }.toMap()
}

val verifyReleaseAdMobIds = tasks.register("verifyReleaseAdMobIds") {
    group = "verification"
    description = "Fails release builds that still carry test or placeholder AdMob ids."

    // Read at configuration time so the task stays configuration-cache friendly.
    val appId = (project.findProperty("admobAppId") as String?)?.trim()
    val bannerId = dartDefines()["ADMOB_BANNER_ANDROID"]

    doLast {
        val problems = listOfNotNull(
            admobIdProblem(appId, appId = true)?.let {
                "AdMob app id (-PadmobAppId or admobAppId in android/gradle.properties) $it."
            },
            admobIdProblem(bannerId, appId = false)?.let {
                "ADMOB_BANNER_ANDROID (--dart-define / secrets.json) $it."
            },
        )
        if (problems.isNotEmpty()) {
            throw GradleException(
                "Release build blocked: test or placeholder AdMob ids.\n  - " +
                    problems.joinToString("\n  - ") +
                    "\nSee ADMOB_SETUP_GUIDE.md / RELEASE_TODO_BLAKE.md. Debug builds keep the test ids."
            )
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild" || name == "assembleRelease" || name == "bundleRelease") {
        dependsOn(verifyReleaseSigning)
        dependsOn(verifyReleaseAdMobIds)
    }
}

flutter {
    source = "../.."
}
