pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }

    plugins {
        id("com.android.application") version "7.3.0" apply false
        id("org.jetbrains.kotlin.android") version "1.7.10" apply false
        id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    }

    // Read Flutter SDK path from local.properties
    val localProperties = java.util.Properties()
    val localPropertiesFile = java.io.File(settingsDir, "local.properties")
    if (!localPropertiesFile.exists()) {
        throw org.gradle.api.GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
    }
    localProperties.load(localPropertiesFile.inputStream())
    val flutterSdkPath = localProperties.getProperty("flutter.sdk")
        ?: throw org.gradle.api.GradleException("Flutter SDK not found. Define flutter.sdk in local.properties file.")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
}

@Suppress("UnstableApiUsage")
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("https://maven.google.com") }
    }
}

include(":app")
