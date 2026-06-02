package com.follow.clash.plugins

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.getSystemService
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import com.follow.clash.R
import com.follow.clash.common.Components
import com.follow.clash.common.GlobalState
import com.follow.clash.common.QuickAction
import com.follow.clash.common.quickIntent
import com.follow.clash.getPackageIconPath
import com.follow.clash.models.Package
import com.follow.clash.showToast
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.lang.ref.WeakReference

class AppPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    companion object {
        const val VPN_PERMISSION_REQUEST_CODE = 1001
        const val NOTIFICATION_PERMISSION_REQUEST_CODE = 1002
    }

    private var activityRef: WeakReference<Activity>? = null

    private lateinit var channel: MethodChannel

    private lateinit var scope: CoroutineScope

    private var vpnPrepareCallback: (suspend () -> Unit)? = null

    private var requestNotificationCallback: (() -> Unit)? = null

    private val packages = mutableListOf<Package>()

    private val skipPrefixList = listOf(
        "com.google",
        "com.android.chrome",
        "com.android.vending",
        "com.microsoft",
        "com.apple",
        "com.zhiliaoapp.musically", // Banned by China
    )

    private val chinaAppPrefixList = listOf(
        "com.tencent",
        "com.alibaba",
        "com.umeng",
        "com.qihoo",
        "com.ali",
        "com.alipay",
        "com.amap",
        "com.sina",
        "com.weibo",
        "com.vivo",
        "com.xiaomi",
        "com.huawei",
        "com.taobao",
        "com.secneo",
        "s.h.e.l.l",
        "com.stub",
        "com.kiwisec",
        "com.secshell",
        "com.wrapper",
        "cn.securitystack",
        "com.mogosec",
        "com.secoen",
        "com.netease",
        "com.mx",
        "com.qq.e",
        "com.baidu",
        "com.bytedance",
        "com.bugly",
        "com.miui",
        "com.oppo",
        "com.coloros",
        "com.iqoo",
        "com.meizu",
        "com.gionee",
        "cn.nubia",
        "com.oplus",
        "andes.oplus",
        "com.unionpay",
        "cn.wps"
    )

    private val chinaAppRegex by lazy {
        ("(" + chinaAppPrefixList.joinToString("|").replace(".", "\\.") + ").*").toRegex()
    }

    private var isBlockNotification: Boolean = false

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "moveTaskToBack" -> {
                activityRef?.get()?.moveTaskToBack(true)
                result.success(true)
            }

            "updateExcludeFromRecents" -> {
                val value = call.argument<Boolean>("value")
                updateExcludeFromRecents(value)
                result.success(true)
            }

            "initShortcuts" -> {
                initShortcuts(call.arguments as String)
                result.success(true)
            }

            "getPackages" -> {
                scope.launch {
                    result.success(getPackagesToJson())
                }
            }

            "getChinaPackageNames" -> {
                scope.launch {
                    result.success(getChinaPackageNames())
                }
            }

            "getPackageIcon" -> {
                handleGetPackageIcon(call, result)
            }

            "tip" -> {
                val message = call.argument<String>("message")
                tip(message)
                result.success(true)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun handleGetPackageIcon(call: MethodCall, result: Result) {
        scope.launch {
            val packageName = call.argument<String>("packageName")
            if (packageName == null) {
                result.success("")
                return@launch
            }
            val path = GlobalState.application.packageManager.getPackageIconPath(packageName)
            result.success(path)
        }
    }

    private fun initShortcuts(label: String) {
        val shortcut = with(ShortcutInfoCompat.Builder(GlobalState.application, "toggle")) {
            setShortLabel(label)
            setIcon(
                IconCompat.createWithResource(
                    GlobalState.application,
                    R.mipmap.ic_launcher_round,
                )
            )
            setIntent(QuickAction.TOGGLE.quickIntent)
            build()
        }
        ShortcutManagerCompat.setDynamicShortcuts(
            GlobalState.application, listOf(shortcut)
        )
    }

    private fun tip(message: String?) {
        GlobalState.application.showToast(message)
    }

    @Suppress("DEPRECATION")
    private fun updateExcludeFromRecents(value: Boolean?) {
        val am = getSystemService(GlobalState.application, ActivityManager::class.java)
        val task = am?.appTasks?.firstOrNull {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                it.taskInfo.taskId == activityRef?.get()?.taskId
            } else {
                it.taskInfo.id == activityRef?.get()?.taskId
            }
        }

        when (value) {
            true -> task?.setExcludeFromRecents(value)
            false -> task?.setExcludeFromRecents(value)
            null -> task?.setExcludeFromRecents(false)
        }
    }


    private fun getPackages(): List<Package> {
        val packageManager = GlobalState.application.packageManager
        if (packages.isNotEmpty()) return packages
        val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        val launcherPackages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                launcherIntent,
                PackageManager.ResolveInfoFlags.of(0)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(launcherIntent, 0)
        }
        launcherPackages
            .mapNotNull { it.activityInfo?.applicationInfo }
            .distinctBy { it.packageName }
            .filter {
                it.packageName != GlobalState.application.packageName && it.packageName != "android"
            }.mapNotNull {
                val packageInfo = try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageManager.getPackageInfo(
                            it.packageName,
                            PackageManager.PackageInfoFlags.of(0)
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getPackageInfo(it.packageName, 0)
                    }
                } catch (_: Exception) {
                    return@mapNotNull null
                }
                Package(
                    packageName = it.packageName,
                    label = it.loadLabel(packageManager).toString(),
                    system = (it.flags and ApplicationInfo.FLAG_SYSTEM) != 0,
                    lastUpdateTime = packageInfo.lastUpdateTime,
                    internet = true
                )
            }.let { packages.addAll(it) }
        return packages
    }

    private suspend fun getPackagesToJson(): String {
        return withContext(Dispatchers.Default) {
            Gson().toJson(getPackages())
        }
    }

    private suspend fun getChinaPackageNames(): String {
        return withContext(Dispatchers.Default) {
            val packages: List<String> =
                getPackages().map { it.packageName }.filter { isChinaPackage(it) }
            Gson().toJson(packages)
        }
    }

    fun requestNotificationsPermission(callBack: () -> Unit) {
        requestNotificationCallback = callBack
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permission = ContextCompat.checkSelfPermission(
                GlobalState.application, Manifest.permission.POST_NOTIFICATIONS
            )
            if (permission == PackageManager.PERMISSION_GRANTED || isBlockNotification) {
                invokeRequestNotificationCallback()
                return
            }
            activityRef?.get()?.let {
                ActivityCompat.requestPermissions(
                    it,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
            }
            return
        } else {
            invokeRequestNotificationCallback()
        }

    }

    fun invokeRequestNotificationCallback() {
        requestNotificationCallback?.invoke()
        requestNotificationCallback = null
    }

    fun prepare(needPrepare: Boolean, callBack: (suspend () -> Unit)) {
        vpnPrepareCallback = callBack
        if (!needPrepare) {
            invokeVpnPrepareCallback()
            return
        }
        val intent = VpnService.prepare(GlobalState.application)
        if (intent != null) {
            activityRef?.get()?.startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
            return
        }
        invokeVpnPrepareCallback()
    }

    fun invokeVpnPrepareCallback() {
        GlobalState.launch {
            vpnPrepareCallback?.invoke()
            vpnPrepareCallback = null
        }
    }


    private fun isChinaPackage(packageName: String): Boolean {
        skipPrefixList.forEach {
            if (packageName == it || packageName.startsWith("$it.")) return false
        }
        return packageName.matches(chinaAppRegex)
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        scope = CoroutineScope(Dispatchers.Default)
        channel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "${Components.PACKAGE_NAME}/app")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityRef = WeakReference(binding.activity)
        binding.addActivityResultListener(::onActivityResult)
        binding.addRequestPermissionsResultListener(::onRequestPermissionsResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityRef = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityRef = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {
        channel.invokeMethod("exit", null)
        activityRef = null
    }

    private fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            if (resultCode == FlutterActivity.RESULT_OK) {
                invokeVpnPrepareCallback()
            }
        }
        return true
    }

    private fun onRequestPermissionsResultListener(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ): Boolean {
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST_CODE) {
            isBlockNotification = true
        }
        invokeRequestNotificationCallback()
        return true
    }
}
