package com.follow.clash.service.modules

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class NotificationUpdatePolicyTest {
    @Test
    fun `allows first foreground update immediately`() {
        val policy = NotificationUpdatePolicy(minUpdateIntervalMillis = 3_000)

        assertTrue(
            policy.shouldUpdate(
                nowMillis = 1_000,
                screenOn = true,
                params = ExtendedNotificationParams(
                    title = "Profile",
                    stopText = "Stop",
                    onlyStatisticsProxy = false,
                    contentText = "0B/s",
                ),
            )
        )
    }

    @Test
    fun `throttles unchanged foreground updates`() {
        val policy = NotificationUpdatePolicy(minUpdateIntervalMillis = 3_000)
        val params = ExtendedNotificationParams(
            title = "Profile",
            stopText = "Stop",
            onlyStatisticsProxy = false,
            contentText = "0B/s",
        )

        assertTrue(policy.shouldUpdate(1_000, screenOn = true, params))
        assertFalse(policy.shouldUpdate(2_000, screenOn = true, params))
    }

    @Test
    fun `allows changed foreground update after interval`() {
        val policy = NotificationUpdatePolicy(minUpdateIntervalMillis = 3_000)
        val oldParams = ExtendedNotificationParams(
            title = "Profile",
            stopText = "Stop",
            onlyStatisticsProxy = false,
            contentText = "0B/s",
        )
        val newParams = oldParams.copy(contentText = "1KB/s")

        assertTrue(policy.shouldUpdate(1_000, screenOn = true, oldParams))
        assertFalse(policy.shouldUpdate(3_999, screenOn = true, newParams))
        assertTrue(policy.shouldUpdate(4_000, screenOn = true, newParams))
    }

    @Test
    fun `blocks screen off speed-only updates`() {
        val policy = NotificationUpdatePolicy(minUpdateIntervalMillis = 3_000)
        val params = ExtendedNotificationParams(
            title = "Profile",
            stopText = "Stop",
            onlyStatisticsProxy = false,
            contentText = "0B/s",
        )

        assertTrue(policy.shouldUpdate(1_000, screenOn = true, params))
        assertFalse(
            policy.shouldUpdate(
                nowMillis = 10_000,
                screenOn = false,
                params = params.copy(contentText = "1KB/s"),
            )
        )
    }

    @Test
    fun `allows screen off structural updates`() {
        val policy = NotificationUpdatePolicy(minUpdateIntervalMillis = 3_000)
        val params = ExtendedNotificationParams(
            title = "Profile",
            stopText = "Stop",
            onlyStatisticsProxy = false,
            contentText = "0B/s",
        )

        assertTrue(policy.shouldUpdate(1_000, screenOn = true, params))
        assertTrue(
            policy.shouldUpdate(
                nowMillis = 10_000,
                screenOn = false,
                params = params.copy(title = "Other Profile"),
            )
        )
    }
}
