allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// file_picker 8.x pins compileSdk 34, but newer transitive plugins
// (flutter_plugin_android_lifecycle 2.0.35) require compileSdk >= 36,
// which fails their AAR metadata checks. Force 36 on every Android
// subproject. Reflection keeps this working across AGP DSL versions.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val setter = androidExt.javaClass.methods
            .firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
        if (setter != null) {
            setter.invoke(androidExt, 36)
        } else {
            logger.info("rozgar: compileSdk override skipped for :$name (no setter found)")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
