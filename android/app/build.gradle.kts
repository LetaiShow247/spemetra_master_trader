import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Helper to load local properties for offline building
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.spemetra_master_trade"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            // Prioritizes GitHub Secrets (Env Vars), falls back to local key.properties
            keyAlias = System.getenv("KEY_ALIAS") 
                ?: keystoreProperties.getProperty("keyAlias") 
                ?: "upload"
            
            keyPassword = System.getenv("KEY_PASSWORD") 
                ?: keystoreProperties.getProperty("keyPassword")
            
            storePassword = System.getenv("KEYSTORE_PASSWORD") 
                ?: keystoreProperties.getProperty("storePassword")

            // On GitHub, we decode the file to 'upload-keystore.jks'
            // Locally, it uses the path defined in your key.properties
            val storePath = System.getenv("KEYSTORE_FILE") 
                ?: keystoreProperties.getProperty("storeFile") 
                ?: "upload-keystore.jks"
            
            storeFile = file(storePath)
        }
    }

    defaultConfig {
        applicationId = "com.spemetra_master_trade"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Updated from 'debug' to use our new 'release' config
            signingConfig = signingConfigs.getByName("release")
            
            minifyEnabled = false
            shrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}