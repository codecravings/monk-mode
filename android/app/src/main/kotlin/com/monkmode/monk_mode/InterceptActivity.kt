package com.monkmode.monk_mode

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/**
 * Transparent trampoline activity that receives intercept intent from the
 * AccessibilityService and redirects into the Flutter access-flow.
 */
class InterceptActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val packageName = intent.getStringExtra("packageName") ?: ""
        val appName = intent.getStringExtra("appName") ?: "App"

        // Launch main Flutter activity with deep link to access flow
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra("intercept_package", packageName)
            putExtra("intercept_app_name", appName)
            data = android.net.Uri.parse(
                "monkmode://access-flow/why?packageName=${
                    java.net.URLEncoder.encode(packageName, "UTF-8")
                }&appName=${
                    java.net.URLEncoder.encode(appName, "UTF-8")
                }"
            )
        }
        startActivity(mainIntent)
        finish()
    }
}
