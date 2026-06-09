import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'item.dart';
import 'requests_updates.dart';

class RequestsView extends ConsumerStatefulWidget {
  const RequestsView({super.key});

  @override
  ConsumerState<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends ConsumerState<RequestsView>
    with WidgetsBindingObserver {
  final _requestsStateNotifier = ValueNotifier<TrackerInfosState>(
    const TrackerInfosState(),
  );
  List<TrackerInfo> _requests = [];
  late final ScrollController _scrollController;

  bool get _shouldUpdateView => shouldUpdateRequestsView(
    isRequestsCurrent: ref.read(isCurrentPageProvider(PageLabel.requests)),
    isAppResumed: isAppLifecycleResumed(WidgetsBinding.instance.lifecycleState),
  );

  void _onSearch(String value) {
    _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
      query: value,
    );
  }

  void _onKeywordsUpdate(List<String> keywords) {
    _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
      keywords: keywords,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requests = ref.read(requestsProvider).list;
    _scrollController = ScrollController(initialScrollOffset: double.maxFinite);
    _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
      trackerInfos: _requests,
    );
    ref.listenManual(requestsProvider.select((state) => state.list), (
      prev,
      next,
    ) {
      _requests = next;
      if (!_shouldUpdateView) {
        return;
      }
      updateRequestsThrottler();
    });
    ref.listenManual(isCurrentPageProvider(PageLabel.requests), (
      previous,
      next,
    ) {
      if (next) {
        updateRequestsThrottler();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      updateRequestsThrottler();
      return;
    }
    throttler.cancel(FunctionTag.requests);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _requestsStateNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void updateRequestsThrottler() {
    if (!_shouldUpdateView) {
      return;
    }
    throttler.call(FunctionTag.requests, () {
      if (!mounted || !_shouldUpdateView) {
        return;
      }
      final isEquality = trackerInfoListEquality.equals(
        _requests,
        _requestsStateNotifier.value.trackerInfos,
      );
      if (isEquality) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shouldUpdateView) {
          _requestsStateNotifier.value = _requestsStateNotifier.value.copyWith(
            trackerInfos: _requests,
          );
        }
      });
    }, duration: commonDuration);
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: appLocalizations.requests,
      searchState: AppBarSearchState(onSearch: _onSearch),
      onKeywordsUpdate: _onKeywordsUpdate,
      floatingActionButton: ValueListenableBuilder(
        valueListenable: _requestsStateNotifier,
        builder: (_, state, _) {
          final autoScrollToEnd = state.autoScrollToEnd;
          return FadeRotationScaleBox(
            child: FloatingActionButton(
              key: ValueKey(autoScrollToEnd),
              onPressed: () {
                _requestsStateNotifier.value = _requestsStateNotifier.value
                    .copyWith(
                      autoScrollToEnd:
                          !_requestsStateNotifier.value.autoScrollToEnd,
                    );
              },
              child: autoScrollToEnd
                  ? const Icon(Icons.block)
                  : const Icon(Icons.vertical_align_top),
            ),
          );
        },
      ),
      body: ValueListenableBuilder<TrackerInfosState>(
        valueListenable: _requestsStateNotifier,
        builder: (context, state, _) {
          final requests = state.list;
          if (requests.isEmpty) {
            return NullStatus(
              label: appLocalizations.nullTip(appLocalizations.requests),
            );
          }
          final items = LazySeparatedList(requests);
          return Align(
            alignment: Alignment.topCenter,
            child: CommonScrollBar(
              trackVisibility: false,
              controller: _scrollController,
              child: ScrollToEndBox(
                controller: _scrollController,
                dataSource: requests,
                enable: state.autoScrollToEnd,
                onCancelToEnd: () {
                  _requestsStateNotifier.value = _requestsStateNotifier.value
                      .copyWith(autoScrollToEnd: false);
                },
                child: SuperListView.builder(
                  reverse: true,
                  shrinkWrap: true,
                  physics: NextClampingScrollPhysics(),
                  controller: _scrollController,
                  itemBuilder: (_, index) {
                    if (items.isSeparator(index)) {
                      return const Divider(height: 0);
                    }
                    final trackerInfo = items.itemAt(index);
                    return TrackerInfoItem(
                      key: Key(trackerInfo.id),
                      trackerInfo: trackerInfo,
                      onClickKeyword: (value) {
                        context.commonScaffoldState?.addKeyword(value);
                      },
                      detailTitle: appLocalizations.details(
                        appLocalizations.request,
                      ),
                    );
                  },
                  itemCount: items.length,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
