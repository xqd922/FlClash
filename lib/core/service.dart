import 'dart:async';

import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/common/system.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/core.dart';
import 'package:flutter/foundation.dart';

import 'desktop/helper_client.dart';
import 'desktop/launcher.dart';
import 'desktop/lifecycle.dart';
import 'desktop/model.dart';
import 'desktop/rpc_client.dart';
import 'desktop/transport.dart';
import 'event.dart';
import 'interface.dart';
import 'method.dart';

class CoreService extends CoreHandlerInterface {
  static CoreService? _instance;

  final DesktopCoreLifecycleController _lifecycle;
  final CoreRpcChannel _rpcClient;
  late final StreamSubscription<DesktopCoreFailure> _crashSubscription;
  Future<CoreLifecycleResult>? _closeOperation;

  @override
  bool get isCompleted {
    // 容忍状态源异常(如测试替身未打桩),视为未运行
    try {
      final DesktopCoreState? state = _lifecycle.state;
      return state is DesktopCoreRunning;
    } catch (_) {
      return false;
    }
  }

  factory CoreService() {
    return _instance ??= CoreService._create();
  }

  factory CoreService._create() {
    final address = system.isWindows ? windowsPipeName : unixSocketPath;
    final directLauncher = DirectCoreLauncher();

    final lifecycle = DesktopCoreLifecycle(
      transportFactory: () => IPCCoreTransport(address: address),
      launcherResolver: WindowsHelperLauncherResolver(
        isWindows: system.isWindows,
        directLauncher: directLauncher,
        helperLauncher: WindowsHelperLauncher(windowsHelperClient),
        helperReady: () => windowsHelperClient.readiness(),
      ),
      verifyPeerPid: system.isWindows,
    );
    return CoreService._(
      lifecycle: lifecycle,
      rpcClient: CoreRpcClient(lifecycle.transport),
    );
  }

  @visibleForTesting
  CoreService.forTesting({
    required DesktopCoreLifecycleController lifecycle,
    required CoreRpcChannel rpcClient,
  }) : this._(lifecycle: lifecycle, rpcClient: rpcClient);

  CoreService._({
    required DesktopCoreLifecycleController lifecycle,
    required CoreRpcChannel rpcClient,
  }) : _lifecycle = lifecycle,
       _rpcClient = rpcClient {
    _crashSubscription = _lifecycle.crashEvents.listen((failure) {
      coreEventManager.sendEvent(
        CoreEvent(
          type: CoreEventType.crash,
          data: failure.cause?.toString() ?? 'core done',
        ),
      );
    });
  }

  @override
  Future<CoreLifecycleResult> start() => _lifecycle.start();

  @override
  Future<CoreLifecycleResult> restart() => _lifecycle.restart();

  @override
  Future<CoreLifecycleResult> stop() async {
    // 本地定制:停止前清空外部控制器,避免 REST 端口残留暴露
    if (isCompleted) {
      try {
        await updateExternalController('');
      } catch (_) {
        // 内核可能已退出,忽略
      }
    }
    return _lifecycle.stop();
  }

  @override
  Future<CoreLifecycleResult> close() {
    return _closeOperation ??= _close();
  }

  Future<CoreLifecycleResult> _close() async {
    try {
      return await _lifecycle.close();
    } finally {
      await _rpcClient.close();
      await _crashSubscription.cancel();
    }
  }

  @override
  Future<T?> invokeMethod<T>({
    required CoreMethod method,
    Object? arguments,
    Duration? timeout,
  }) {
    return _rpcClient.invoke<T>(
      method: method,
      arguments: arguments,
      timeout: timeout,
    );
  }
}

final coreService = system.isDesktop ? CoreService() : null;
