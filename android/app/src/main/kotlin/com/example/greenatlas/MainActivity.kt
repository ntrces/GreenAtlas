package com.example.greenatlas

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val diagnosticsChannel = "com.example.greenatlas/ar_diagnostics"
    private val appUpdatesChannel = "com.example.greenatlas/app_updates"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, diagnosticsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "getArDiagnostics") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val arCorePackage = "com.google.ar.core"
                var installed = false
                var enabled = false
                var versionName: String? = null
                var versionCode: Long? = null

                try {
                    val info = packageManager.getPackageInfo(arCorePackage, 0)
                    installed = true
                    enabled = info.applicationInfo?.enabled == true
                    versionName = info.versionName
                    versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        info.longVersionCode
                    } else {
                        @Suppress("DEPRECATION")
                        info.versionCode.toLong()
                    }
                } catch (_: PackageManager.NameNotFoundException) {
                    // Reported below as an explicit package state.
                }

                val cameraGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }

                result.success(
                    mapOf(
                        "arCoreInstalled" to installed,
                        "arCoreEnabled" to enabled,
                        "arCoreVersionName" to versionName,
                        "arCoreVersionCode" to versionCode,
                        "cameraGranted" to cameraGranted,
                        "hasArCameraFeature" to packageManager.hasSystemFeature("android.hardware.camera.ar"),
                        "manufacturer" to Build.MANUFACTURER,
                        "model" to Build.MODEL,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT
                    )
                )
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appUpdatesChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "getAppVersion") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                try {
                    val info = packageManager.getPackageInfo(packageName, 0)
                    result.success(info.versionName ?: "0.0.0")
                } catch (error: Exception) {
                    result.error(
                        "APP_VERSION_UNAVAILABLE",
                        "GreenAtlas could not read its installed version.",
                        error.message
                    )
                }
            }
    }
}
