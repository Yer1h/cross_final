buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

plugins {
    kotlin("android") version "2.1.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set custom root build directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    // Each subproject uses a custom build directory under the root
    val subprojectBuildDir = newBuildDir.dir(name)
    layout.buildDirectory.set(subprojectBuildDir)

    // Ensure the app module is evaluated before others
    evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
