group "com.austrianapps.flutter_watch_garmin_connectiq"
version "1.0-SNAPSHOT"


buildscript {
    val kotlinVersion = "1.7.10"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    compileSdkVersion(31)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets["main"].java {
        srcDir("src/main/kotlin")
    }
    sourceSets["test"].java {
        srcDir("src/test/kotlin")
    }

    defaultConfig {
        minSdkVersion(16)
    }

    dependencies {
        testImplementation("org.jetbrains.kotlin:kotlin-test")
        testImplementation("org.mockito:mockito-core:5.0.0")
    }

//    testOptions {
//        unitTests.all {
//            useJUnitPlatform()
//
//            testLogging {
//               events "passed", "skipped", "failed", "standardOut", "standardError"
//               outputs.upToDateWhen {false}
//               showStandardStreams = true
//            }
//        }
//    }
}