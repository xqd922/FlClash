import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'connections_polling.dart';
import 'connections_updates.dart';
import 'item.dart';

class ConnectionsView extends ConsumerStatefulWidget {
  const ConnectionsView({super.key});

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView> {
  final _connectionsStateNotifier = ValueNotifier<TrackerInfosState>(
    const TrackerInfosState(),
  );
  final ScrollController _scrollController = ScrollController();

  Timer? _timer;

  bool get _shouldPoll => shouldPollConnections(
    isConnectionsCurrent: ref.read(
      isCurrentPageProvider(PageLabel.connections),
    ),
  );

  List<Widget> _buildActions() {
    return [
      IconButton(
        onPressed: () async {
          coreController.closeConnections();
          await _updateConnections();
        },
        icon: const Icon(Icons.delete_sweep_outlined),
      ),
    ];
  }

  void _onSearch(String value) {
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      query: value,
    );
  }

  void _onKeywordsUpdate(List<String> keywords) {
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      keywords: keywords,
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleNextUpdate() {
    _cancelTimer();
    if (!_shouldPoll) {
      return;
    }
    _timer = Timer(connectionsPollingInterval, _updateConnectionsTask);
  }

  void _updateConnectionsTask() {
    if (!_shouldPoll) {
      _cancelTimer();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      await _updateConnections();
      if (!mounted) {
        return;
      }
      _scheduleNextUpdate();
    });
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(isCurrentPageProvider(PageLabel.connections), (
      previous,
      next,
    ) {
      if (next) {
        _updateConnectionsTask();
      } else {
        _cancelTimer();
      }
    }, fireImmediately: true);
  }

  Future<void> _updateConnections() async {
    final nextConnections = await coreController.getConnections();
    if (!shouldUpdateConnectionsList(
      _connectionsStateNotifier.value.trackerInfos,
      nextConnections,
    )) {
      return;
    }
    _connectionsStateNotifier.value = _connectionsStateNotifier.value.copyWith(
      trackerInfos: nextConnections,
    );
  }

  Future<void> _handleBlockConnection(String id) async {
    coreController.closeConnection(id);
    await _updateConnections();
  }

  @override
  void dispose() {
    _cancelTimer();
    _connectionsStateNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: appLocalizations.connections,
      onKeywordsUpdate: _onKeywordsUpdate,
      searchState: AppBarSearchState(onSearch: _onSearch),
      actions: _buildActions(),
      body: ValueListenableBuilder<TrackerInfosState>(
        valueListenable: _connectionsStateNotifier,
        builder: (context, state, _) {
          final connections = state.list;
          if (connections.isEmpty) {
            return NullStatus(
              label: appLocalizations.nullTip(appLocalizations.connections),
              illustration: ConnectionEmptyIllustration(),
            );
          }
          return ConnectionsList(
            controller: _scrollController,
            connections: connections,
            onClickKeyword: (value) {
              context.commonScaffoldState?.addKeyword(value);
            },
            onBlockConnection: _handleBlockConnection,
          );
        },
      ),
    );
  }
}

class ConnectionsList extends StatelessWidget {
  const ConnectionsList({
    super.key,
    required this.connections,
    required this.onClickKeyword,
    required this.onBlockConnection,
    this.controller,
  });

  final List<TrackerInfo> connections;
  final ValueChanged<String> onClickKeyword;
  final ValueChanged<String> onBlockConnection;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final items = LazySeparatedList(connections);
    return SuperListView.builder(
      controller: controller,
      itemBuilder: (context, index) {
        if (items.isSeparator(index)) {
          return const Divider(height: 0);
        }
        final trackerInfo = items.itemAt(index);
        return TrackerInfoItem(
          key: Key(trackerInfo.id),
          trackerInfo: trackerInfo,
          onClickKeyword: onClickKeyword,
          trailing: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(minimumSize: Size.zero),
            icon: const Icon(Icons.block),
            onPressed: () {
              onBlockConnection(trackerInfo.id);
            },
          ),
          detailTitle: appLocalizations.details(appLocalizations.connection),
        );
      },
      itemCount: items.length,
    );
  }
}
