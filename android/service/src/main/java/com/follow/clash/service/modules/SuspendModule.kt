package com.follow.clash.service.modules

import android.app.Service
import android.content.Intent
import android.os.PowerManager
import androidx.core.content.getSystemService
import com.follow.clash.common.GlobalState
import com.follow.clash.common.receiveBroadcastFlow
import com.follow.clash.core.Core
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onStart
import kotlinx.coroutines.launch

internal class SuspendModule(
    private val service: Service,
    private val scope: CoroutineScope,
) : ServiceModule {
    private fun isScreenOn() =
        service.getSystemService<PowerManager>()?.isInteractive ?: true

    private val isDeviceIdle: Boolean
        get() = service.getSystemService<PowerManager>()?.isDeviceIdleMode ?: true

    // 仅在挂起状态翻转时调用内核,避免重复 JNI 调用
    private var isSuspended = false

    private fun updateSuspension(screenOn: Boolean) {
        val shouldSuspend = !screenOn && isDeviceIdle
        if (shouldSuspend == isSuspended) {
            return
        }
        isSuspended = shouldSuspend
        GlobalState.log(if (shouldSuspend) "Entering Doze" else "Exiting Doze")
        Core.suspended(shouldSuspend)
    }

    override fun start() {
        scope.launch {
            val screenFlow = service.receiveBroadcastFlow {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(PowerManager.ACTION_DEVICE_IDLE_MODE_CHANGED)
            }.map {
                isScreenOn()
            }.onStart {
                emit(isScreenOn())
            }

            screenFlow.collect(::updateSuspension)
        }
    }

    override fun stop() {
        isSuspended = false
        Core.suspended(false)
    }
}
