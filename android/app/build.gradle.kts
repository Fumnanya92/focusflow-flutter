import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.focusflow.productivity"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.focusflow.productivity"
        minSdk = flutter.minSdkVersion
        targetSdk = 35  // Required for Google Play
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    // Signing configurations
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }

    lint {
        // Disable lint checks that are not critical for release
        disable.addAll(listOf("IconMissingDensityFolder", "IconDensities", "IconLauncherFormat"))
        // Treat lint warnings as non-fatal for release builds
        abortOnError = false
        checkReleaseBuilds = true
    }

    buildTypes {
        release {
            // Use proper release signing configuration
            signingConfig = signingConfigs.getByName("release")
            // Enable standard R8 optimization with Flutter-compatible settings
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // Ensure proper Flutter optimization
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Modern Play libraries (SDK 34+ compliant)
    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:review:2.0.1")
    
    // Kotlin stdlib for R8 compatibility
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.10")
}

// Force resolution strategy to replace old Play Core
configurations.all {
    resolutionStrategy {
        force("com.google.android.play:app-update:2.1.0")
        eachDependency {
            if (requested.group == "com.google.android.play" && requested.name == "core") {
                useTarget("com.google.android.play:app-update:2.1.0")
                because("Replace legacy Play Core with modern app-update")
            }
        }
    }
    exclude(group = "com.google.android.play", module = "core")
}

flutter {
    source = "../.."
}
