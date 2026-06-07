import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:flutter/material.dart';

@immutable
class DonutChartData {
  final double _value;
  final Color color;

  const DonutChartData({required double value, required this.color})
    : _value = value + 1;

  double get value => _value;

  @override
  String toString() {
    return 'DonutChartData{_value: $_value}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutChartData &&
          runtimeType == other.runtimeType &&
          _value == other._value &&
          color == other.color;

  @override
  int get hashCode => _value.hashCode ^ color.hashCode;
}

const _donutChartLogBase = 10.0;
const _donutChartMinValue = 0.1;
final _donutChartLogBaseInv = 1.0 / log(_donutChartLogBase);

double _logDonutChartValue(double value) {
  if (value < _donutChartMinValue) return 0;
  return log(value) * _donutChartLogBaseInv + 1;
}

double _expDonutChartValue(double value) {
  if (value <= 0) return 0;
  return pow(_donutChartLogBase, value - 1).toDouble();
}

double interpolateDonutChartValue(
  double oldValue,
  double newValue,
  double progress,
) {
  if (progress <= 0) return oldValue;
  if (progress >= 1) return newValue;
  final logOldValue = _logDonutChartValue(oldValue);
  final logNewValue = _logDonutChartValue(newValue);
  return _expDonutChartValue(
    logOldValue + (logNewValue - logOldValue) * progress,
  );
}

class DonutChart extends StatefulWidget {
  final List<DonutChartData> data;
  final Duration duration;

  const DonutChart({
    super.key,
    required this.data,
    this.duration = commonDuration,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<DonutChartData> _oldData;

  @override
  void initState() {
    super.initState();
    _oldData = widget.data;
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _oldData = oldWidget.data;
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: DonutChartPainter(
            _oldData,
            widget.data,
            _animationController.value,
          ),
        );
      },
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<DonutChartData> oldData;
  final List<DonutChartData> newData;
  final double progress;

  late final Paint _arcPaint;

  DonutChartPainter(this.oldData, this.newData, this.progress) {
    _arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
  }

  double _getValue(int index) {
    if (oldData.length != newData.length) {
      return newData[index].value;
    }
    return interpolateDonutChartValue(
      oldData[index].value,
      newData[index].value,
      progress,
    );
  }

  double _getTotalValue() {
    var total = 0.0;
    for (var i = 0; i < newData.length; i++) {
      total += _getValue(i);
    }
    return total;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (newData.isEmpty) return;

    final total = _getTotalValue();
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 10.0.ap;
    final radius = min(size.width / 2, size.height / 2) - strokeWidth / 2;

    final gapAngle = 2 * asin(strokeWidth * 1 / (2 * radius)) * 1.2;
    final availableAngle = 2 * pi - (newData.length * gapAngle);
    final totalInv = 1.0 / total;

    double startAngle = -pi / 2 + gapAngle / 2;

    _arcPaint.strokeWidth = strokeWidth;

    for (var i = 0; i < newData.length; i++) {
      final sweepAngle = availableAngle * (_getValue(i) * totalInv);

      if (sweepAngle <= 0) continue;

      _arcPaint.color = newData[i].color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        _arcPaint,
      );

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.oldData != oldData ||
        oldDelegate.newData != newData;
  }
}
