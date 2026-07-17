plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt.android)
}

// ---------------------------------------------------------------------------
// Signing
//
// One keystore, one key alias, used to sign every build of every variant,
// forever. This is the fix for "package appears to be corrupt" / "package
// conflicts with an existing package" on update: Android refuses to install
// an APK over an existing app unless it is signed with the exact same
// certificate. If signing ever silently falls back to a fresh,
// auto-generated debug keystore (which is what happens if you let the
// Android Gradle Plugin create one for you on an ephemeral CI runner),
// every build gets a new signature and every "update" looks like a
// different app to Android.
//
// Credentials are read from environment variables so nothing secret is ever
// committed to git. GitHub Actions decodes the keystore secret to a file
// and exports these before invoking Gradle. See scripts/create_keystore.sh
// and docs/SIGNING.md for the one-time setup.
// ---------------------------------------------------------------------------
val keystorePath: String? = System.getenv("SF_KEYSTORE_PATH")
val keystorePassword: String? = System.getenv("SF_KEYSTORE_PASSWORD")
val sfKeyAlias: String? = System.getenv("SF_KEY_ALIAS")
val sfKeyPassword: String? = System.getenv("SF_KEY_PASSWORD")
val hasSigningConfig = !keystorePath.isNullOrBlank() &&
    !keystorePassword.isNullOrBlank() &&
    !sfKeyAlias.isNullOrBlank() &&
    !sfKeyPassword.isNullOrBlank() &&
    file(keystorePath).exists()

// versionCode must strictly increase for every release, or Android treats a
// build as not-newer and some install flows refuse it. GITHUB_RUN_NUMBER
// increases automatically on every workflow run, so this is never something
// you have to remember to bump by hand. Outside CI (e.g. a stray local
// invocation) it falls back to 1.
val ciRunNumber = System.getenv("GITHUB_RUN_NUMBER")?.toIntOrNull() ?: 1

android {
    namespace = "com.surffountain.browser"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.surffountain.browser"
        minSdk = 29
        targetSdk = 36
        versionCode = ciRunNumber
        versionName = "0.1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables { useSupportLibrary = true }
    }

    signingConfigs {
        if (hasSigningConfig) {
            create("surfFountain") {
                storeFile = file(keystorePath!!)
                storePassword = keystorePassword
                keyAlias = sfKeyAlias
                keyPassword = sfKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            // Distinct applicationId so a debug build can live side-by-side
            // with a release build on the same device without ever
            // conflicting with it.
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            isDebuggable = true
            if (hasSigningConfig) {
                signingConfig = signingConfigs.getByName("surfFountain")
            }
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (hasSigningConfig) {
                signingConfig = signingConfigs.getByName("surfFountain")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

ksp {
    arg("room.schemaLocation", "$projectDir/schemas")
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.splashscreen)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.foundation)
    implementation(libs.androidx.material.icons.core)
    implementation(libs.androidx.material3)
    debugImplementation(libs.androidx.ui.tooling)

    implementation(libs.androidx.navigation.compose)

    implementation(libs.androidx.room.runtime)
    implementation(libs.androidx.room.ktx)
    ksp(libs.androidx.room.compiler)

    implementation(libs.androidx.datastore.preferences)

    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.androidx.hilt.navigation.compose)

    implementation(libs.kotlinx.coroutines.android)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.androidx.room.testing)

    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
}
