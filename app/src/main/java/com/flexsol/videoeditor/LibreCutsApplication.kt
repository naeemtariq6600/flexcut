package com.flexsol.videoeditor

import android.app.Application
import android.content.Intent
import android.util.Log
import com.flexsol.videoeditor.ads.AdMobConfig
import com.flexsol.videoeditor.utils.ErrorCode
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration

class LibreCutsApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        setupGlobalCrashHandler()
        MobileAds.setRequestConfiguration(
            RequestConfiguration.Builder()
                .setTestDeviceIds(listOf(AdMobConfig.TEST_DEVICE_ID))
                .build()
        )
        MobileAds.initialize(this)
    }

    private fun setupGlobalCrashHandler() {
        val oldHandler = Thread.getDefaultUncaughtExceptionHandler()

        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            Log.e("LibreCutsCrash", "CRITICAL CRASH IN APPLICATION", throwable)

            // Start a dedicated Error Activity to show the dialog
            val intent = Intent(this, ErrorDisplayActivity::class.java).apply {
                putExtra("ERROR_CODE", ErrorCode.UNEXPECTED_CRASH.code)
                putExtra("ERROR_LOG", Log.getStackTraceString(throwable))
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            }
            startActivity(intent)

            // Terminate the crashed process
            android.os.Process.killProcess(android.os.Process.myPid())
            System.exit(1)
        }
    }
}
