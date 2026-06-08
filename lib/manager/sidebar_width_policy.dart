import 'dart:math';

const sideWidthEpsilon = 0.001;

double computeSideWidth({
  required double viewWidth,
  required double contentWidth,
}) {
  return max(viewWidth - contentWidth, 0);
}

bool shouldUpdateSideWidth({
  required double currentSideWidth,
  required double viewWidth,
  required double contentWidth,
}) {
  final nextSideWidth = computeSideWidth(
    viewWidth: viewWidth,
    contentWidth: contentWidth,
  );
  return (currentSideWidth - nextSideWidth).abs() > sideWidthEpsilon;
}
