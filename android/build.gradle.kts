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
    val configureProject = {
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            // 1. Force compileSdkVersion / compileSdk to 36
            try {
                val setCompileSdk = androidExt::class.java.getMethod("setCompileSdk", java.lang.Integer::class.java)
                setCompileSdk.invoke(androidExt, 36)
            } catch (e: Exception) {
                try {
                    val setCompileSdkVersion = androidExt::class.java.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdkVersion.invoke(androidExt, 36)
                } catch (e2: Exception) {
                    // Ignore
                }
            }

            // 2. Set namespace if missing
            try {
                val getNamespace = androidExt::class.java.getMethod("getNamespace")
                val namespace = getNamespace.invoke(androidExt) as? String
                if (namespace == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val packageName = Regex("""package="([^"]*)"""").find(manifestFile.readText())?.groups?.get(1)?.value
                        if (packageName != null) {
                            val setNamespace = androidExt::class.java.getMethod("setNamespace", String::class.java)
                            setNamespace.invoke(androidExt, packageName)
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    if (project.state.executed) {
        configureProject()
    } else {
        project.afterEvaluate {
            configureProject()
        }
    }
}
