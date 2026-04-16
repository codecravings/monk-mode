package com.monkmode.monk_mode

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class MonkModeAccessibilityService : AccessibilityService() {

    private var lastInterceptedPackage = ""
    private var lastInterceptTime = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == this.packageName) return
        if (packageName == "android") return
        if (packageName.startsWith("com.android.")) return
        if (packageName == "com.google.android.inputmethod.latin") return

        val lockedPackages = getLockedPackages()
        if (!lockedPackages.contains(packageName)) return

        val now = System.currentTimeMillis()
        if (packageName == lastInterceptedPackage && (now - lastInterceptTime) < 3000) return

        lastInterceptedPackage = packageName
        lastInterceptTime = now

        val appName = getAppName(packageName)
        launchInterceptActivity(packageName, appName)
    }

    override fun onInterrupt() {}

    private fun getLockedPackages(): Set<String> {
        val prefs = getSharedPreferences("monk_mode_native", Context.MODE_PRIVATE)
        return prefs.getStringSet("locked_packages", emptySet()) ?: emptySet()
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun launchInterceptActivity(packageName: String, appName: String) {
        val intent = Intent(this, InterceptActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("packageName", packageName)
            putExtra("appName", appName)
        }
        startActivity(intent)
    }
}
