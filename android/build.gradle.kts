import java.util.Properties

plugins {
    id("com.android.application")
    kotlin("android")
    kotlin("plugin.compose")
    kotlin("plugin.serialization") version "2.0.21"
}

// Copy shared Data from Hedaya/Data into assets so the app can load groups and azkar JSON
val copyDataToAssets = tasks.register<Copy>("copyDataToAssets") {
    from("${rootProject.projectDir}/Hedaya/Data")
    into(project.file("src/main/assets/data"))
}

// Release signing is read from an untracked keystore.properties at the repo root.
// See ANDROID_PUBLICATION_GUIDE.md §2. If the file is absent the release build still
// succeeds but the artifact is UNSIGNED and Play Console will reject it.
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseKeystore = !keystoreProperties.getProperty("storeFile").isNullOrBlank()

android {
    namespace = "com.hedaya.android"
    // Google Play requires new releases to target API 36 (Android 16) as of 2026-08-31.
    compileSdk = 36
    defaultConfig {
        applicationId = "com.hedaya.android"
        minSdk = 24
        targetSdk = 36
        // versionCode must increase on every Play upload; 1 is the first-ever upload.
        versionCode = 1
        // Keep in step with iOS MARKETING_VERSION in Hedaya.xcodeproj.
        versionName = "1.6"
    }
    buildFeatures {
        compose = true
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "Hedaya: keystore.properties not found — :android:bundleRelease will produce an " +
                        "UNSIGNED bundle that Play Console will reject. See ANDROID_PUBLICATION_GUIDE.md §2."
                )
                null
            }
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

tasks.findByName("preBuild")?.dependsOn(copyDataToAssets)

dependencies {
    implementation(project(":shared"))
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")
    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.navigation:navigation-compose:2.7.7")
    implementation("androidx.datastore:datastore-preferences:1.0.0")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")

    // Prayer times calculation
    implementation("com.batoulapps.adhan:adhan:1.2.1")

    // Location services
    implementation("com.google.android.gms:play-services-location:21.3.0")
}
