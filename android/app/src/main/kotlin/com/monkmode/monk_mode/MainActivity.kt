package com.monkmode.monk_mode

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.monkmode.app/bridge"
    private val PREFS_NAME = "monk_mode_native"
    private val KEY_LOCKED = "locked_packages"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getInstalledApps" -> result.success(getInstalledApps())
                        "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())
                        "openAccessibilitySettings" -> {
                            val i = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(i)
                            result.success(null)
                        }
                        "isUsageStatsPermissionGranted" -> result.success(isUsageStatsGranted())
                        "openUsageStatsSettings" -> {
                            val i = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(i)
                            result.success(null)
                        }
                        "isDefaultLauncher" -> result.success(isDefaultLauncher())
                        "requestDefaultLauncher" -> {
                            requestDefaultLauncher()
                            result.success(null)
                        }
                        "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                        "openBatteryOptimizationSettings" -> {
                            openBatteryOptimizationSettings()
                            result.success(null)
                        }
                        "getAppUsageStats" -> {
                            val pkg = call.argument<String>("packageName") ?: ""
                            val start = (call.argument<Number>("start"))?.toLong()
                                ?: (System.currentTimeMillis() - 7L * 24 * 60 * 60 * 1000)
                            val end = (call.argument<Number>("end"))?.toLong()
                                ?: System.currentTimeMillis()
                            result.success(getAppUsageStats(pkg, start, end))
                        }
                        "launchApp" -> {
                            val pkg = call.argument<String>("packageName") ?: ""
                            val ok = launchApp(pkg)
                            result.success(ok)
                        }
                        "updateLockedPackages" -> {
                            val packages = call.argument<List<String>>("packages") ?: emptyList()
                            saveLockedPackages(packages)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("NATIVE_ERROR", e.message, null)
                }
            }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val resolved = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, 0)
        }

        val seen = mutableSetOf<String>()
        val apps = mutableListOf<Map<String, Any>>()
        for (ri in resolved) {
            val pkg = ri.activityInfo.packageName
            if (pkg == this.packageName) continue
            if (!seen.add(pkg)) continue
            val appName = ri.loadLabel(pm).toString()
            val isSystem = (ri.activityInfo.applicationInfo.flags and
                    android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
            apps.add(
                mapOf(
                    "packageName" to pkg,
                    "appName" to appName,
                    "isSystemApp" to isSystem
                )
            )
        }
        return apps
    }

    private fun isAccessibilityEnabled(): Boolean {
        val serviceName =
            "${this.packageName}/${MonkModeAccessibilityService::class.java.canonicalName}"
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(":").any { it.equals(serviceName, ignoreCase = true) }
    }

    private fun isUsageStatsGranted(): Boolean {
        return try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    packageName
                )
            }
            mode == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            false
        }
    }

    private fun isDefaultLauncher(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
            val ri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.resolveActivity(
                    intent,
                    PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong())
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            }
            ri?.activityInfo?.packageName == packageName
        } catch (_: Exception) {
            false
        }
    }

    private fun requestDefaultLauncher() {
        try {
            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (_: Exception) {
            val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(fallback)
        }
    }

    @Suppress("NewApi")
    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return try {
            val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            pm.isIgnoringBatteryOptimizations(packageName)
        } catch (_: Exception) {
            true
        }
    }

    private fun openBatteryOptimizationSettings() {
        try {
            val i = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(i)
        } catch (_: Exception) {
            // ignore
        }
    }

    private fun getAppUsageStats(packageName: String, startTime: Long, endTime: Long): Map<String, Any> {
        val empty = mapOf<String, Any>(
            "granted" to false,
            "totalMinutes" to 0,
            "openCount" to 0,
            "lastOpenTimestamp" to 0L,
            "lastSessionMinutes" to 0,
            "avgSessionMinutes" to 0
        )
        if (!isUsageStatsGranted()) return empty
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return empty

        val events = usm.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()
        var openCount = 0
        var totalMs = 0L
        var lastOpenTs = 0L
        var lastSessionMs = 0L
        var sessionStart = 0L
        val sessionDurations = mutableListOf<Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.packageName != packageName) continue
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    sessionStart = event.timeStamp
                    lastOpenTs = event.timeStamp
                    openCount++
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    if (sessionStart > 0L) {
                        val dur = event.timeStamp - sessionStart
                        if (dur in 1..(8 * 60 * 60 * 1000L)) {
                            totalMs += dur
                            sessionDurations.add(dur)
                            lastSessionMs = dur
                        }
                        sessionStart = 0L
                    }
                }
            }
        }

        val avgMs = if (sessionDurations.isNotEmpty())
            sessionDurations.sum() / sessionDurations.size else 0L

        return mapOf(
            "granted" to true,
            "totalMinutes" to (totalMs / 60000L).toInt(),
            "openCount" to openCount,
            "lastOpenTimestamp" to lastOpenTs,
            "lastSessionMinutes" to (lastSessionMs / 60000L).toInt(),
            "avgSessionMinutes" to (avgMs / 60000L).toInt()
        )
    }

    private fun launchApp(packageName: String): Boolean {
        return try {
            val launchIntent = this.packageManager.getLaunchIntentForPackage(packageName)
                ?: return false
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(launchIntent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun saveLockedPackages(packages: List<String>) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_LOCKED, packages.toSet()).apply()
    }
}
