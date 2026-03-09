import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
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
      child: Wrap(
        runSpacing: 16,
        children: [
          InfoHeader(
            info: Info(
              label: appLocalizations.themeMode,
              iconData: Icons.brightness_high,
            ),
          ),
          Container(
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
        ],
      ),
    );
  }
}
