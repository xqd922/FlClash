import 'package:fl_clash/common/common.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

class CommonFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Icon icon;
  final String tooltip;

  const CommonFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return TooltipTheme(
      // The FAB's Tooltip defaults to a long-press recognizer, which holds the
      // press highlight back until the pointer lifts. Manual registers none,
      // and hover and semantics stay on the tooltip either way.
      data: TooltipTheme.of(
        context,
      ).copyWith(triggerMode: TooltipTriggerMode.manual),
      child: FloatingActionButton(
        heroTag: null,
        tooltip: tooltip,
        onPressed: onPressed,
        child: icon,
      ),
    );
  }
}

class MoreActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final Widget? trailing;

  const MoreActionButton({
    super.key,
    this.onPressed,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CommonCard(
        radius: AppCorner.xl,
        onPressed: onPressed,
        child: ListTile(
          minTileHeight: 0,
          minVerticalPadding: 0,
          titleTextStyle: context.textTheme.bodyMedium?.toJetBrainsMono,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          title: Text(label, style: context.textTheme.bodyLarge),
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 18),
        ),
      ),
    );
  }
}
