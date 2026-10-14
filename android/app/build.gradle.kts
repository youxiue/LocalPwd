import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val appName = "LocalPwd"

// 读取正式 release 签名配置（android/key.properties，已被 .gitignore 排除）
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.localpwd.local_pwd"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.localpwd.local_pwd"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // 优先使用正式签名；未提供 key.properties 时回退 debug 签名并告警
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
                logger.warn(
                    "LocalPwd: 未找到 android/key.properties，release 构建使用 debug 签名，仅供本地测试，请勿分发。"
                )
            }
        }
    }
}

// Flutter Gradle 插件会覆盖标准 APK 输出名，通过 doLast 在构建完成后复制出自定义名称的 APK
project.afterEvaluate {
    tasks.matching { it.name.startsWith("assemble") && (it.name.contains("Release") || it.name.contains("Debug")) }
        .configureEach {
            doLast {
                // Flutter APK 输出在项目根目录的 build/ 下，而非模块 build 目录
                val flutterRoot = rootProject.projectDir.parentFile
                val apkDir = File(flutterRoot, "build/app/outputs/flutter-apk")
                if (!apkDir.exists()) return@doLast
                apkDir.listFiles()?.forEach { file ->
                    if (file.name.endsWith(".apk") && !file.name.startsWith(appName)) {
                        val buildType = if (file.name.contains("release")) "release" else "debug"
                        val newName = "$appName-$buildType-v${android.defaultConfig.versionName}.apk"
                        val newFile = File(file.parentFile, newName)
                        // 复制而非重命名，避免 Flutter 找不到原始 APK
                        file.copyTo(newFile, overwrite = true)
                    }
                }
            }
        }
}

flutter {
    source = "../.."
}
