import 'package:flutter/material.dart';

const startButtonRuntimeCharacterWidth = 9.0;
const startButtonRuntimeHorizontalPadding = 16.0;
const startButtonIconHeight = 56.0;
const startButtonIconSize = 24.0;
const startButtonIconLeftPadding = 16.0;
const startButtonIconRightPadding = 16.0;
const startButtonIconExpandedRightPadding = 8.0;
const startButtonMaxWidth = 200.0;
const startButtonSizeConstraints = BoxConstraints(
  minWidth: startButtonIconHeight,
  maxWidth: startButtonMaxWidth,
  minHeight: startButtonIconHeight,
  maxHeight: startButtonIconHeight,
);

double startButtonWidthForText(String text, double progress) {
  final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
  final width =
      startButtonIconLeftPadding +
      startButtonIconSize +
      startButtonExpandedIconRightPadding(clampedProgress) +
      estimatedStartButtonTextWidth(text) * clampedProgress;
  return width.clamp(startButtonIconHeight, startButtonMaxWidth).toDouble();
}

double startButtonTextWidth(double measuredTextWidth) {
  return _paddedWidth(measuredTextWidth, startButtonRuntimeHorizontalPadding);
}

double estimatedStartButtonTextWidth(String text) {
  return startButtonTextWidth(
    _estimatedTextWidth(text, startButtonRuntimeCharacterWidth),
  );
}

double startButtonExpandedIconRightPadding(double progress) {
  final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
  return startButtonIconRightPadding -
      (startButtonIconRightPadding - startButtonIconExpandedRightPadding) *
          clampedProgress;
}

double _paddedWidth(double measuredTextWidth, double padding) {
  return (measuredTextWidth < 0 ? 0 : measuredTextWidth) + padding;
}

double _estimatedTextWidth(String text, double characterWidth) {
  return text.length * characterWidth;
}
