import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';

class TrafficUsageViewData {
  const TrafficUsageViewData({
    required this.uploadValue,
    required this.downloadValue,
    required this.donutData,
  });

  final num uploadValue;
  final num downloadValue;
  final List<DonutChartData> donutData;
}

TrafficUsageViewData buildTrafficUsageViewData(
  Traffic totalTraffic, {
  required Color uploadColor,
  required Color downloadColor,
}) {
  final uploadValue = totalTraffic.up;
  final downloadValue = totalTraffic.down;
  return TrafficUsageViewData(
    uploadValue: uploadValue,
    downloadValue: downloadValue,
    donutData: [
      DonutChartData(value: uploadValue.toDouble(), color: uploadColor),
      DonutChartData(value: downloadValue.toDouble(), color: downloadColor),
    ],
  );
}
