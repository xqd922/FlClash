package com.follow.clash.service.modules

abstract class Module {

    private var isInstall: Boolean = false

    protected abstract fun onInstall()
    protected abstract fun onUninstall()

    fun install() {
        // NOTE: 防止重复安装导致资源泄漏（如 NotificationModule 的 scope）。
        if (isInstall) return
        isInstall = true
        onInstall()
    }

    fun uninstall() {
        if (!isInstall) return
        onUninstall()
        isInstall = false
    }
}