allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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

// ── Compatibility shim for legacy plugins ───────────────────────────────────
// AGP 8.x requires every Android module to declare `android.namespace`, but
// some older plugins (e.g. flutter_branch_sdk 6.x) only declare the legacy
// `package="..."` attribute in their AndroidManifest.xml and fail with
// "Namespace not specified". This injects the namespace from the manifest
// for any module that is missing one. The hook fires the moment the Android
// plugin is applied (before AGP creates variants), which is required because
// the evaluationDependsOn(":app") call above evaluates subprojects eagerly —
// an afterEvaluate hook would run too late. Remove this block once all
// plugins support AGP 8 natively.
subprojects {
    val injectNamespaceFromManifest: Project.() -> Unit = {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getter = androidExt.javaClass.getMethod("getNamespace")
                if (getter.invoke(androidExt) == null) {
                    val manifest = file("src/main/AndroidManifest.xml")
                    val pkg = Regex("package=\"([^\"]+)\"")
                        .find(manifest.readText())
                        ?.groupValues
                        ?.getOrNull(1)
                    if (pkg != null) {
                        androidExt.javaClass
                            .getMethod("setNamespace", String::class.java)
                            .invoke(androidExt, pkg)
                    }
                }
            } catch (_: Exception) {
                // Not an Android module or API mismatch — nothing to do.
            }
        }
    }
    plugins.withId("com.android.library") { injectNamespaceFromManifest() }
    plugins.withId("com.android.application") { injectNamespaceFromManifest() }
}
