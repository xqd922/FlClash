const startButtonRuntimeCharacterWidth = 9.0;

double startButtonTextWidth(double measuredTextWidth) {
  return (measuredTextWidth < 0 ? 0 : measuredTextWidth) + 16;
}

double estimatedStartButtonTextWidth(String text) {
  return startButtonTextWidth(text.length * startButtonRuntimeCharacterWidth);
}
