package com.follow.clash.service.modules

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

interface ModuleLoaderScope {
    fun <T : Module> install(module: T): T
}

interface ModuleLoader {
    fun load()

    fun cancel()
}

private val mutex = Mutex()
fun CoroutineScope.moduleLoader(block: suspend ModuleLoaderScope.() -> Unit): ModuleLoader {
    val modules = mutableListOf<Module>()
    var job: Job? = null

    return object : ModuleLoader {
        override fun load() {
            job = launch(Dispatchers.IO) {
                mutex.withLock {
                    val scope = object : ModuleLoaderScope {
                        override fun <T : Module> install(module: T): T {
                            modules.add(module)
                            module.install()
                            return module
                        }
                    }
                    scope.block()
                }
            }
        }

        // NOTE: 用 runBlocking 确保模块卸载在 cancel() 返回前完成。
        // 原来 launch 异步执行，Service.onDestroy 后模块可能还没卸载干净。
        override fun cancel() {
            runBlocking(Dispatchers.IO) {
                job?.cancel()
                mutex.withLock {
                    modules.asReversed().forEach { it.uninstall() }
                    modules.clear()
                }
            }
        }
    }
}