import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_clash/application_auto_update.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/connectivity_policy.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/manager/hotkey_manager.dart';
import 'package:fl_clash/manager/manager.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controller.dart';
import 'pages/pages.dart';

class Application extends ConsumerStatefulWidget {
  const Application({super.key});

  @override
  ConsumerState<Application> createState() => ApplicationState();
}

class ApplicationState extends ConsumerState<Application>
    with WidgetsBindingObserver {
  Timer? _autoUpdateProfilesTaskTimer;
  List<ConnectivityResult>? _lastConnectivityResults;

  final _pageTransitionsTheme = const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: commonSharedXPageTransitions,
      TargetPlatform.windows: commonSharedXPageTransitions,
      TargetPlatform.linux: commonSharedXPageTransitions,
      TargetPlatform.macOS: commonSharedXPageTransitions,
    },
  );

  ColorScheme _getAppColorScheme({required Brightness brightness}) {
    return ref.read(genColorSchemeProvider(brightness));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(profilesProvider, (previous, next) {
      _syncProfileAutoUpdateTimer();
    }, fireImmediately: true);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final currentContext = globalState.navigatorKey.currentContext;
      if (currentContext != null) {
        await appController.attach(currentContext, ref);
      } else {
        exit(0);
      }
      _syncProfileAutoUpdateTimer();
      appController.initLink();
      app?.initShortcuts();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncProfileAutoUpdateTimer();
  }

  void _cancelProfileAutoUpdateTimer() {
    _autoUpdateProfilesTaskTimer?.cancel();
    _autoUpdateProfilesTaskTimer = null;
  }

  bool get _shouldScheduleProfileAutoUpdate {
    return shouldScheduleProfileAutoUpdate(
      profiles: ref.read(profilesProvider),
      lifecycleState: WidgetsBinding.instance.lifecycleState,
    );
  }

  void _syncProfileAutoUpdateTimer() {
    if (!_shouldScheduleProfileAutoUpdate) {
      _cancelProfileAutoUpdateTimer();
      return;
    }
    if (_autoUpdateProfilesTaskTimer?.isActive == true) {
      return;
    }
    _autoUpdateProfilesTaskTimer = Timer(
      profileAutoUpdateCheckInterval,
      () async {
        _autoUpdateProfilesTaskTimer = null;
        if (!_shouldScheduleProfileAutoUpdate) {
          return;
        }
        await appController.autoUpdateProfiles();
        if (mounted) {
          _syncProfileAutoUpdateTimer();
        }
      },
    );
  }

  Widget _buildPlatformState({required Widget child}) {
    if (system.isDesktop) {
      return WindowManager(
        child: TrayManager(
          child: HotKeyManager(child: ProxyManager(child: child)),
        ),
      );
    }
    return AndroidManager(child: TileManager(child: child));
  }

  Widget _buildState({required Widget child}) {
    return AppStateManager(
      child: CoreManager(
        child: ConnectivityManager(
          onConnectivityChanged: (results) async {
            final previousResults = _lastConnectivityResults;
            _lastConnectivityResults = results;
            commonPrint.log('connectivityChanged ${results.toString()}');
            appController.updateLocalIp();
            if (shouldCheckIpAfterConnectivityChange(
              previousResults: previousResults,
              nextResults: results,
            )) {
              appController.tryCheckIp();
            }
          },
          child: child,
        ),
      ),
    );
  }

  Widget _buildPlatformApp({required Widget child}) {
    if (system.isDesktop) {
      return WindowHeaderContainer(child: child);
    }
    return VpnManager(child: child);
  }

  Widget _buildApp({required Widget child}) {
    return StatusManager(child: ThemeManager(child: child));
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (_, ref, child) {
        final locale = ref.watch(
          appSettingProvider.select((state) => state.locale),
        );
        final themeMode = ref.watch(
          themeSettingProvider.select((state) => state.themeMode),
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: globalState.navigatorKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (_, child) {
            return AppEnvManager(
              child: _buildApp(
                child: _buildPlatformState(
                  child: _buildState(child: _buildPlatformApp(child: child!)),
                ),
              ),
            );
          },
          scrollBehavior: BaseScrollBehavior(),
          title: appName,
          locale: utils.getLocaleForString(locale),
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            pageTransitionsTheme: _pageTransitionsTheme,
            colorScheme: _getAppColorScheme(brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            pageTransitionsTheme: _pageTransitionsTheme,
            colorScheme: _getAppColorScheme(brightness: Brightness.dark),
          ),
          home: child!,
        );
      },
      child: const HomePage(),
    );
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    linkManager.destroy();
    _cancelProfileAutoUpdateTimer();
    await coreController.destroy();
    await appController.handleExit();
    super.dispose();
  }
}
