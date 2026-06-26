package com.follow.clash.service.modules

import android.util.Log
import java.net.NetworkInterface

object VpnResidualCleaner {
    private const val TAG = "VpnResidualCleaner"
    private const val POLL_INTERVAL_MS = 250L

    fun hasTunInterface(): Boolean {
        return try {
            NetworkInterface.getNetworkInterfaces()?.toList()?.any {
                it.name.startsWith("tun") && it.isUp
            } ?: false
        } catch (_: Exception) {
            false
        }
    }

    // NOTE: Thread.sleep 阻塞调用线程（最大 3 秒）。仅在 VPN 启动时调用一次，
    // 频率低，改为 suspend 需要改 IBaseService 接口，收益不大。
    fun waitForTunRelease(timeoutMs: Long = 3000L): Boolean {
        val start = System.currentTimeMillis()
        while (System.currentTimeMillis() - start < timeoutMs) {
            if (!hasTunInterface()) {
                Log.d(TAG, "TUN interface released")
                return true
            }
            Thread.sleep(POLL_INTERVAL_MS)
        }
        Log.w(TAG, "TUN interface release timeout")
        return false
    }
}
