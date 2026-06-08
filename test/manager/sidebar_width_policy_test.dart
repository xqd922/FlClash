import 'package:fl_clash/manager/sidebar_width_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sidebar width policy', () {
    test('computes side width from view and content widths', () {
      expect(computeSideWidth(viewWidth: 1200, contentWidth: 980), 220);
      expect(computeSideWidth(viewWidth: 980, contentWidth: 1200), 0);
    });

    test('skips provider writes when side width is unchanged', () {
      expect(
        shouldUpdateSideWidth(
          currentSideWidth: 220,
          viewWidth: 1200,
          contentWidth: 980,
        ),
        isFalse,
      );
      expect(
        shouldUpdateSideWidth(
          currentSideWidth: 180,
          viewWidth: 1200,
          contentWidth: 980,
        ),
        isTrue,
      );
    });

    test('treats tiny layout jitter as unchanged', () {
      expect(
        shouldUpdateSideWidth(
          currentSideWidth: 220,
          viewWidth: 1200.0000001,
          contentWidth: 980,
        ),
        isFalse,
      );
    });
  });
}
