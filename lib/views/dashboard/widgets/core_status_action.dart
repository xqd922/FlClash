import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';

const coreStatusActionMaxWidth = 160.0;

class CoreStatusAction extends StatelessWidget {
  const CoreStatusAction({
    super.key,
    required this.coreStatus,
    required this.onPressed,
  });

  final CoreStatus coreStatus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (coreStatus == CoreStatus.connected) {
      return IconButton.filled(
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: _backgroundColor(context),
          foregroundColor: _connectedIconForegroundColor(context),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.check, fontWeight: FontWeight.w900),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: coreStatusActionMaxWidth),
      child: FilledButton.icon(
        key: ValueKey(coreStatus),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: _backgroundColor(context),
          foregroundColor: _buttonForegroundColor(context),
        ),
        icon: _CoreStatusIcon(coreStatus: coreStatus),
        label: Text(_label(), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Color? _backgroundColor(BuildContext context) {
    return switch (coreStatus) {
      CoreStatus.connecting => null,
      CoreStatus.connected => Colors.greenAccent,
      CoreStatus.disconnected => context.colorScheme.error,
    };
  }

  Color? _buttonForegroundColor(BuildContext context) {
    return switch (coreStatus) {
      CoreStatus.connecting => null,
      CoreStatus.connected => switch (Theme.brightnessOf(context)) {
        Brightness.light => context.colorScheme.onSurfaceVariant,
        Brightness.dark => null,
      },
      CoreStatus.disconnected => context.colorScheme.onError,
    };
  }

  Color _connectedIconForegroundColor(BuildContext context) {
    return switch (Theme.brightnessOf(context)) {
      Brightness.light => context.colorScheme.onSurfaceVariant,
      Brightness.dark => context.colorScheme.onPrimaryFixedVariant,
    };
  }

  String _label() {
    return switch (coreStatus) {
      CoreStatus.connecting => appLocalizations.connecting,
      CoreStatus.connected => appLocalizations.connected,
      CoreStatus.disconnected => appLocalizations.disconnected,
    };
  }
}

class _CoreStatusIcon extends StatelessWidget {
  const _CoreStatusIcon({required this.coreStatus});

  final CoreStatus coreStatus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: globalState.measure.bodyMediumHeight,
      width: globalState.measure.bodyMediumHeight,
      child: switch (coreStatus) {
        CoreStatus.connecting => Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: context.colorScheme.onPrimary,
            backgroundColor: Colors.transparent,
          ),
        ),
        CoreStatus.connected => const Icon(
          Icons.check_sharp,
          fontWeight: FontWeight.w900,
        ),
        CoreStatus.disconnected => const Icon(
          Icons.restart_alt_sharp,
          fontWeight: FontWeight.w900,
        ),
      },
    );
  }
}
