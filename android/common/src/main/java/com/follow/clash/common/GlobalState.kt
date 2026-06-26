package com.follow.clash.common


import android.app.Application
import android.util.Log
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers

object GlobalState : CoroutineScope by CoroutineScope(Dispatchers.Default) {

    const val NOTIFICATION_CHANNEL = "FlClash"

    const val NOTIFICATION_ID = 1

    // NOTE: 共享 Gson 实例，避免每次调用都创建（涉及反射，开销不小）。
    val gson = Gson()

    val packageName: String
        get() = application.packageName

    val RECEIVE_BROADCASTS_PERMISSIONS: String
        get() = "${packageName}.permission.RECEIVE_BROADCASTS"


    private var _application: Application? = null

    // NOTE: 提供明确错误信息，原来的 !! 操作符 NPE 没有任何上下文。
    val application: Application
        get() = _application ?: throw IllegalStateException(
            "GlobalState.init(application) must be called before accessing application"
        )


    fun log(text: String) {
        Log.d("[FlClash]", text)
    }

    fun init(application: Application) {
        _application = application
    }
}
