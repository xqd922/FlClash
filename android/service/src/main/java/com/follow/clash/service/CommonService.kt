package com.follow.clash.service

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import com.follow.clash.common.GlobalState
import com.follow.clash.core.Core
import com.follow.clash.service.modules.NetworkObserveModule
import com.follow.clash.service.modules.NotificationModule
import com.follow.clash.service.modules.SuspendModule
import com.follow.clash.service.modules.moduleLoader
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

// NOTE: 加 SupervisorJob，onDestroy 中取消 scope 防止协程泄漏。
class CommonService : Service(), IBaseService,
    CoroutineScope by CoroutineScope(SupervisorJob() + Dispatchers.Default) {

    private val self: CommonService
        get() = this

    private val loader = moduleLoader {
        install(NetworkObserveModule(self))
        install(NotificationModule(self))
        install(SuspendModule(self))
    }

    override fun onCreate() {
        super.onCreate()
        handleCreate()
    }

    override fun onDestroy() {
        cancel()
        handleDestroy()
        super.onDestroy()
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) {
            Core.forceGC()
        }
    }

    private val binder = LocalBinder()

    inner class LocalBinder : Binder() {
        fun getService(): CommonService = this@CommonService
    }

    override fun onBind(intent: Intent): IBinder {
        return binder
    }

    override fun start() {
        try {
            loader.load()
        } catch (e: Exception) {
            GlobalState.log("CommonService start failed: ${e.message}")
            stop()
        }
    }

    override fun stop() {
        loader.cancel()
        stopSelf()
    }
}