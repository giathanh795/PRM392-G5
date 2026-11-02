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
    // AGP creates relative paths between a plugin's sources and build output.
    // On Windows those paths must be on the same drive (Pub cache may be on C:
    // while this checkout is on D:).
    val sourceRoot = project.projectDir.toPath().root
    val outputRoot = newBuildDir.asFile.toPath().root
    if (sourceRoot != outputRoot) {
        val gradleCache = gradle.gradleUserHomeDir
        val buildBase = if (gradleCache.toPath().root == sourceRoot) {
            gradleCache.resolve("flutter-plugin-builds")
        } else {
            project.projectDir.resolve(".gradle-build")
        }
        val checkoutId = rootProject.projectDir.absolutePath.hashCode().toUInt().toString(16)
        project.layout.buildDirectory.set(buildBase.resolve("$checkoutId/${project.name}"))
    } else {
        project.layout.buildDirectory.value(newBuildDir.dir(project.name))
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
    subprojects.forEach { delete(it.layout.buildDirectory) }
}
