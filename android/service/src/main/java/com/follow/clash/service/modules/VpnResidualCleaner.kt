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
