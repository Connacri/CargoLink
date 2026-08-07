allprojects {
    repositories {
        google()
        mavenCentral()
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

// Force compileSdk 36 across all plugin sub-projects. Several dependencies
// (androidx.fragment, androidx.window, etc.) require a newer compileSdk.
fun forceCompileSdk(project: Project) {
    val androidExt = project.extensions.findByName("android")
    if (androidExt is com.android.build.api.dsl.CommonExtension) {
        @Suppress("DEPRECATION")
        androidExt.compileSdk = 36
    }
}
subprojects {
    if (state.executed) {
        forceCompileSdk(this)
    } else {
        afterEvaluate { forceCompileSdk(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
