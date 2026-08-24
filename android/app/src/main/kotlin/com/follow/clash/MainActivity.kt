package com.follow.clash

import android.content.Context
import com.follow.clash.plugins.AppPlugin
import com.follow.clash.plugins.ServicePlugin
import com.follow.clash.plugins.TilePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    companion object {
        private const val ENGINE_ID = "xlclash_main_engine"
    }

    // 复用缓存引擎,Activity 重建时避免重新初始化 Dart isolate 与插件注册
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(ENGINE_ID)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 引擎来自缓存时插件已注册过,判空保证幂等
        if (flutterEngine.plugins.get(AppPlugin::class.java) == null) {
            flutterEngine.plugins.add(AppPlugin())
        }
        if (flutterEngine.plugins.get(ServicePlugin::class.java) == null) {
            flutterEngine.plugins.add(ServicePlugin())
        }
        if (flutterEngine.plugins.get(TilePlugin::class.java) == null) {
            flutterEngine.plugins.add(TilePlugin())
        }
        ServiceState.attachFlutterEngine(flutterEngine)
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onDestroy() {
        flutterEngine?.let(ServiceState::detachFlutterEngine)
        super.onDestroy()
    }
}
