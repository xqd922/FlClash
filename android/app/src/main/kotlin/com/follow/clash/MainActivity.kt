package com.follow.clash

import android.content.Context
import android.os.Bundle
import com.follow.clash.common.GlobalState
import com.follow.clash.plugins.AppPlugin
import com.follow.clash.plugins.ServicePlugin
import com.follow.clash.plugins.TilePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity(),
    CoroutineScope by CoroutineScope(SupervisorJob() + Dispatchers.Default) {

    companion object {
        private const val ENGINE_ID = "xlclash_main_engine"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        val cached = FlutterEngineCache.getInstance().get(ENGINE_ID)
        if (cached != null) {
            return cached
        }
        return null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (flutterEngine.plugins.get(AppPlugin::class.java) == null)
            flutterEngine.plugins.add(AppPlugin())
        if (flutterEngine.plugins.get(ServicePlugin::class.java) == null)
            flutterEngine.plugins.add(ServicePlugin())
        if (flutterEngine.plugins.get(TilePlugin::class.java) == null)
            flutterEngine.plugins.add(TilePlugin())
        State.flutterEngine = flutterEngine
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun onDestroy() {
        GlobalState.launch {
            Service.setEventListener(null)
        }
        State.flutterEngine = null
        super.onDestroy()
    }
}
