// ──────────────────────────────────────────────────────────────────────────────
// android/app/build.gradle.kts
// Demonstrates how to integrate the SMPAndroid Swift module into an Android
// application using the Swift SDK for Android Gradle plugin.
// ──────────────────────────────────────────────────────────────────────────────

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    // Swift SDK for Android Gradle plugin (Google / swift-android-toolchain)
    id("com.google.swift.android") version "0.1.0"
}

android {
    namespace   = "com.example.smp"
    compileSdk  = 35

    defaultConfig {
        applicationId  = "com.example.smp"
        minSdk         = 26
        targetSdk      = 35
        versionCode    = 1
        versionName    = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // Pack the Swift dylib alongside the Kotlin .so files.
    packaging {
        jniLibs.useLegacyPackaging = false
    }
}

// ── Swift SPM integration ─────────────────────────────────────────────────────
swift {
    // Path to the SPM Package.swift at the root of the SMP repo.
    packageDirectory = file("../../")

    // Build only the Android-facing product.
    products = listOf("SMPAndroid")

    // Cross-compilation targets (ABI → Swift triple mapping).
    targets {
        create("arm64-v8a")  { swiftTriple = "aarch64-unknown-linux-android26" }
        create("x86_64")     { swiftTriple = "x86_64-unknown-linux-android26"  }
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.kotlinx.coroutines.android)
}
