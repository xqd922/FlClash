package com.follow.clash.service.modules

import com.follow.clash.core.Core
import com.follow.clash.service.models.NotificationParams
import com.follow.clash.service.models.getSpeedTrafficText

data class ExtendedNotificationParams(
    val title: String,
    val stopText: String,
    val onlyStatisticsProxy: Boolean,
    val contentText: String,
)

class NotificationUpdatePolicy(
    private val minUpdateIntervalMillis: Long = 3_000L,
) {
    private var lastUpdateMillis: Long? = null
    private var lastParams: ExtendedNotificationParams? = null

    fun shouldUpdate(
        nowMillis: Long,
        screenOn: Boolean,
        params: ExtendedNotificationParams,
    ): Boolean {
        val previousParams = lastParams
        if (previousParams == null || lastUpdateMillis == null) {
            record(nowMillis, params)
            return true
        }
        if (!screenOn && params.isSpeedOnlyChangeFrom(previousParams)) {
            return false
        }
        if (params == previousParams) {
            return false
        }
        if (nowMillis - lastUpdateMillis!! < minUpdateIntervalMillis) {
            return false
        }
        record(nowMillis, params)
        return true
    }

    private fun record(nowMillis: Long, params: ExtendedNotificationParams) {
        lastUpdateMillis = nowMillis
        lastParams = params
    }

    private fun ExtendedNotificationParams.isSpeedOnlyChangeFrom(
        previous: ExtendedNotificationParams,
    ): Boolean {
        return title == previous.title &&
                stopText == previous.stopText &&
                onlyStatisticsProxy == previous.onlyStatisticsProxy &&
                contentText != previous.contentText
    }
}

val NotificationParams.extended: ExtendedNotificationParams
    get() = ExtendedNotificationParams(
        title,
        stopText,
        onlyStatisticsProxy,
        Core.getSpeedTrafficText(onlyStatisticsProxy),
    )
