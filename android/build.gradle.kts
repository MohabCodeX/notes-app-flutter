allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// This redirects all subproject build outputs to the Flutter-expected location:
// <project_root>/build/ so that `flutter run` can find the generated APK.
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
