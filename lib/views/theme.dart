// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_color_utilities/hct/hct.dart';

class ThemeModeItem {
  final ThemeMode themeMode;
  final IconData iconData;
  final String label;

  const ThemeModeItem({
    required this.themeMode,
    required this.iconData,
    required this.label,
  });
}

class ThemeView extends StatelessWidget {
  const ThemeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: appLocalizations.theme,
      body: CustomScrollView(
        slivers: [
          _ThemeModeItem(),
          SliverToBoxAdapter(child: SizedBox(height: 16)),
          _PrimaryColorItem(),
          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Widget child;
  final Info info;
  final List<Widget> actions;

  const ItemCard({
    super.key,
    required this.info,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 16,
      children: [
        InfoHeader(info: info, actions: actions),
        child,
      ],
    );
  }
}

class _ThemeModeItem extends ConsumerWidget {
  const _ThemeModeItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    List<ThemeModeItem> themeModeItems = [
      ThemeModeItem(
        iconData: Icons.auto_mode,
        label: appLocalizations.auto,
        themeMode: ThemeMode.system,
      ),
      ThemeModeItem(
        iconData: Icons.light_mode,
        label: appLocalizations.light,
        themeMode: ThemeMode.light,
      ),
      ThemeModeItem(
        iconData: Icons.dark_mode,
        label: appLocalizations.dark,
        themeMode: ThemeMode.dark,
      ),
    ];
    return SliverToBoxAdapter(
      child: ItemCard(
        info: Info(
          label: appLocalizations.themeMode,
          iconData: Icons.brightness_high,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: themeModeItems.length,
            itemBuilder: (_, index) {
              final themeModeItem = themeModeItems[index];
              return CommonCard(
                isSelected: themeModeItem.themeMode == themeMode,
                onPressed: () {
                  ref
                      .read(themeSettingProvider.notifier)
                      .update(
                        (state) =>
                            state.copyWith(themeMode: themeModeItem.themeMode),
                      );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(child: Icon(themeModeItem.iconData)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(themeModeItem.label)),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) {
              return const SizedBox(width: 16);
            },
          ),
        ),
      ),
    );
  }
}

class _PrimaryColorItem extends ConsumerStatefulWidget {
  const _PrimaryColorItem();

  @override
  ConsumerState<_PrimaryColorItem> createState() => _PrimaryColorItemState();
}

class _PrimaryColorItemState extends ConsumerState<_PrimaryColorItem> {
  int? _removablePrimaryColor;

  int _calcColumns(double maxWidth) {
    return max((maxWidth / 96).ceil(), 3);
  }

  Future<void> _handleReset() async {
    final res = await globalState.showMessage(
      message: TextSpan(text: appLocalizations.resetTip),
    );
    if (res != true) {
      return;
    }
    ref.read(themeSettingProvider.notifier).update((state) {
      return state.copyWith(
        primaryColors: defaultPrimaryColors,
        primaryColor: defaultPrimaryColor,
      );
    });
  }

  Future<void> _handleDel() async {
    if (_removablePrimaryColor == null) {
      return;
    }
    final res = await globalState.showMessage(
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.colorSchemes),
      ),
    );
    if (res != true) {
      return;
    }
    ref.read(themeSettingProvider.notifier).update((state) {
      final newPrimaryColors = List<int>.from(state.primaryColors)
        ..remove(_removablePrimaryColor);
      int? newPrimaryColor = state.primaryColor;
      if (state.primaryColor == _removablePrimaryColor) {
        if (newPrimaryColors.contains(defaultPrimaryColor)) {
          newPrimaryColor = defaultPrimaryColor;
        } else {
          newPrimaryColor = null;
        }
      }
      return state.copyWith(
        primaryColors: newPrimaryColors,
        primaryColor: newPrimaryColor,
      );
    });
    setState(() {
      _removablePrimaryColor = null;
    });
  }

  Future<void> _handleAdd() async {
    final res = await globalState.showCommonDialog<int>(
      child: const _PaletteDialog(),
    );
    if (res == null) {
      return;
    }
    final isExists = ref.read(
      themeSettingProvider.select((state) => state.primaryColors.contains(res)),
    );
    if (isExists && mounted) {
      context.showNotifier(
        appLocalizations.existsTip(appLocalizations.colorSchemes),
      );
      return;
    }
    ref.read(themeSettingProvider.notifier).update((state) {
      return state.copyWith(
        primaryColors: List.from(state.primaryColors)..add(res),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(
      themeSettingProvider.select((state) => state.primaryColor),
    );
    final primaryColors = ref.watch(
      themeSettingProvider.select((state) => state.primaryColors),
    );
    final isDefault =
        primaryColor == defaultPrimaryColor &&
        intListEquality.equals(primaryColors, defaultPrimaryColors);
    final allColors = [null, ...primaryColors];

    return SliverToBoxAdapter(
      child: CommonPopScope(
        onPop: (context) {
          if (_removablePrimaryColor != null) {
            setState(() {
              _removablePrimaryColor = null;
            });
            return false;
          }
          return true;
        },
        child: ItemCard(
          info: Info(
            label: appLocalizations.themeColor,
            iconData: Icons.palette,
          ),
          actions: genActions([
            if (_removablePrimaryColor != null)
              FilledButton(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  setState(() {
                    _removablePrimaryColor = null;
                  });
                },
                child: Text(appLocalizations.cancel),
              ),
            if (_removablePrimaryColor == null && !isDefault)
              IconButton.filledTonal(
                iconSize: 20,
                padding: EdgeInsets.all(4),
                visualDensity: VisualDensity.compact,
                onPressed: _handleReset,
                icon: Icon(Icons.replay),
              ),
          ], space: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final columns = _calcColumns(constraints.maxWidth);
                final itemWidth =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final color in allColors)
                      Container(
                        clipBehavior: Clip.none,
                        width: itemWidth,
                        height: itemWidth,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            EffectGestureDetector(
                              child: ColorSchemeBox(
                                isSelected: color == primaryColor,
                                primaryColor: color != null
                                    ? Color(color)
                                    : null,
                                onPressed: () {
                                  setState(() {
                                    _removablePrimaryColor = null;
                                  });
                                  ref
                                      .read(themeSettingProvider.notifier)
                                      .update(
                                        (state) =>
                                            state.copyWith(primaryColor: color),
                                      );
                                },
                              ),
                              onLongPress: () {
                                if (color == null) return;
                                setState(() {
                                  _removablePrimaryColor = color;
                                });
                              },
                            ),
                            if (_removablePrimaryColor != null &&
                                _removablePrimaryColor == color)
                              Container(
                                color: Colors.white.opacity0,
                                padding: EdgeInsets.all(8),
                                child: IconButton.filledTonal(
                                  onPressed: _handleDel,
                                  padding: EdgeInsets.all(12),
                                  iconSize: 30,
                                  icon: Icon(
                                    color: context.colorScheme.primary,
                                    Icons.delete,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (_removablePrimaryColor == null)
                      Container(
                        width: itemWidth,
                        height: itemWidth,
                        padding: EdgeInsets.all(4),
                        child: IconButton.filledTonal(
                          onPressed: _handleAdd,
                          iconSize: 32,
                          icon: Icon(
                            color: context.colorScheme.primary,
                            Icons.add,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteDialog extends StatefulWidget {
  const _PaletteDialog();

  @override
  State<_PaletteDialog> createState() => _PaletteDialogState();
}

class _PaletteDialogState extends State<_PaletteDialog> {
  final _controller = ValueNotifier<Color>(Color(Hct.from(0, 0, 60).toInt()));

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.palette,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(appLocalizations.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_controller.value.toARGB32());
          },
          child: Text(appLocalizations.confirm),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 300, child: Palette(controller: _controller)),
        ],
      ),
    );
  }
}
