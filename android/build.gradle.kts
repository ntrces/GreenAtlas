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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    project.pluginManager.withPlugin("com.android.library") {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getNamespace = androidExt::class.java.getMethod("getNamespace")
                val namespace = getNamespace.invoke(androidExt) as? String
                if (namespace == null) {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val packageName = Regex("""package="([^"]*)"""").find(manifestFile.readText())?.groups?.get(1)?.value
                        if (packageName != null) {
                            val setNamespace = androidExt::class.java.getMethod("setNamespace", String::class.java)
                            setNamespace.invoke(androidExt, packageName)
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore errors if the methods don't exist
            }
        }
    }
}
