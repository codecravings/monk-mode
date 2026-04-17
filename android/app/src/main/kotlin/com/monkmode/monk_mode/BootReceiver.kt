package com.monkmode.monk_mode

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restores Monk Mode state after device boot or app update.
 *
 * The accessibility service is re-bound by the system automatically if enabled,
 * and locked package set persists via SharedPreferences. This receiver simply
 * "touches" the prefs file to ensure it is up-to-date and ready for the service
 * on first foreground query.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                val prefs = context.getSharedPreferences(
                    "monk_mode_native",
                    Context.MODE_PRIVATE
                )
                // No-op touch; ensures the file is created and readable by the service
                prefs.getStringSet("locked_packages", emptySet())
            }
        }
    }
}
