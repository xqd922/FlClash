package com.follow.clash.service.modules

import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.content.getSystemService
import com.follow.clash.common.receiveBroadcastFlow
import com.follow.clash.core.Core
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch


class SuspendModule(private val service: Service) : Module() {
    companion object {
        private const val TAG = "SuspendModule"
    }

    private val scope = CoroutineScope(Dispatchers.Default)
    private var isSuspended = false

    private val powerManager: PowerManager? by lazy {
        service.getSystemService<PowerManager>()
    }

    private val isScreenOn: Boolean
        get() = powerManager?.isInteractive ?: true

    private val isDeviceIdleMode: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && powerManager?.isDeviceIdleMode == true

    private val shouldSuspend: Boolean
        get() = !isScreenOn && isDeviceIdleMode

    private fun updateSuspendState() {
        val shouldSuspendNow = shouldSuspend
        when {
            shouldSuspendNow && !isSuspended -> {
                Log.i(TAG, "Entering Doze - Suspending core")
                Core.suspended(true)
                isSuspended = true
            }
            !shouldSuspendNow && isSuspended -> {
                Log.i(TAG, "Exiting Doze - Resuming core")
                Core.suspended(false)
                isSuspended = false
            }
        }
    }

    override fun onInstall() {
        isSuspended = false
        scope.launch {
            service.receiveBroadcastFlow {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    addAction(PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED)
                }
            }.onStart {
                emit(Intent())
            }.collect {
                updateSuspendState()
            }
        }
    }

    override fun onUninstall() {
        if (isSuspended) {
            Core.suspended(false)
            isSuspended = false
        }
        scope.cancel()
    }
}