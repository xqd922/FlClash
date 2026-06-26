package com.follow.clash

import android.app.Activity
import android.os.Bundle
import com.follow.clash.common.QuickAction
import com.follow.clash.common.action
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

// NOTE: CoroutineScope 必须在 onDestroy 中取消，否则协程泄漏。
class TempActivity : Activity(),
    CoroutineScope by CoroutineScope(SupervisorJob() + Dispatchers.Default) {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // NOTE: finish() 移到协程内，确保 action 完成后再销毁 Activity。
        // 原来 finish() 在 launch 后同步调用，协程可能在 Activity 销毁后访问 context。
        when (intent.action) {
            QuickAction.START.action -> {
                launch {
                    State.handleStartServiceAction()
                    finish()
                }
            }

            QuickAction.STOP.action -> {
                launch {
                    State.handleStopServiceAction()
                    finish()
                }
            }

            QuickAction.TOGGLE.action -> {
                launch {
                    State.handleToggleAction()
                    finish()
                }
            }
        }
    }

    override fun onDestroy() {
        cancel()
        super.onDestroy()
    }
}