import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

// 本地定制：恢复 v7.0.33 的加载动画——一颗持续旋转、角数在 3→9 之间连续往复
// 变形的星形。StarBorder 的 points 支持浮点连续值，角是真实地分裂/合并的；
// 上游 v0.8.97 的 M3E 形状序列指示器（离散顶点逐档变形）替代不了这个观感，
// 故整体回退绘制器，勿用 RoundedPolygon/Morph 重写。
class CommonCircleLoading extends StatefulWidget {
  const CommonCircleLoading({super.key, this.color});

  static const double defaultDimension = 48;

  final Color? color;

  @override
  State<CommonCircleLoading> createState() => _CommonCircleLoadingState();
}

class _CommonCircleLoadingState extends State<CommonCircleLoading>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _pointsController;
  late final Animation<double> _pointsAnimation;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pointsController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pointsAnimation = Tween<double>(begin: 3.0, end: 9.0).animate(
      CurvedAnimation(parent: _pointsController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  double _resolveDimension(BoxConstraints constraints) {
    final maxWidth = math.min(
      constraints.maxWidth,
      CommonCircleLoading.defaultDimension,
    );
    final maxHeight = math.min(
      constraints.maxHeight,
      CommonCircleLoading.defaultDimension,
    );
    if (maxWidth.isFinite && maxHeight.isFinite) {
      return math.min(maxWidth, maxHeight);
    }
    if (maxWidth.isFinite) {
      return maxWidth;
    }
    if (maxHeight.isFinite) {
      return maxHeight;
    }
    return CommonCircleLoading.defaultDimension;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = _resolveDimension(constraints);
        return Align(
          widthFactor: 1,
          heightFactor: 1,
          child: RepaintBoundary(
            child: RotationTransition(
              turns: _rotateController,
              child: SizedBox.square(
                dimension: side,
                child: AnimatedBuilder(
                  animation: _pointsAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _StarPainter(
                        points: _pointsAnimation.value,
                        color: color,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final double points;
  final Color color;
  final Paint _paint;

  _StarPainter({required this.points, required this.color})
    : _paint = Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final starBorder = StarBorder(
      points: points,
      innerRadiusRatio: 0.8,
      pointRounding: 0.5,
      valleyRounding: 0.1,
      squash: 0.5,
    );

    final path = starBorder.getOuterPath(rect);
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
