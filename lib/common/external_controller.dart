const externalControllerKey = 'external-controller';

String resolveExternalController(
  Object? configExternalController, {
  required bool enableExternalController,
}) {
  if (!enableExternalController) {
    return '';
  }
  return switch (configExternalController) {
    final String value => value,
    _ => '',
  };
}
