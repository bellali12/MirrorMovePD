import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mirrormotion/services/data.dart';

class BarChartWidget extends StatefulWidget {
  const BarChartWidget({
    super.key,
    this.weeklyData,
    this.barColor = Colors.white,
    this.goalHitBarColor = const Color.fromARGB(255, 88, 198, 150),
    this.goalBarColor = const Color.fromARGB(255, 109, 125, 131),
    this.labelColor = Colors.white,
    this.tooltipColor = Colors.blueGrey,
    this.barWidth = 22,
    this.labelFontSize = 14,
  });

  final List<WeeklyUsagePoint>? weeklyData;
  final Color barColor;
  final Color goalHitBarColor;
  final Color goalBarColor;
  final Color labelColor;
  final Color tooltipColor;
  final double barWidth;
  final double labelFontSize;

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  int touchedIndex = -1;
  final Duration animDuration = const Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final List<WeeklyUsagePoint> weeklyData =
        widget.weeklyData ?? DataService().getCurrentWeekUsage();
    return BarChart(_mainBarData(weeklyData), duration: animDuration);
  }

  BarChartGroupData _makeGroupData(
    int x,
    WeeklyUsagePoint point, {
    bool isTouched = false,
    List<int> showTooltips = const <int>[],
  }) {
    final bool goalHit =
        point.goalMinutes > 0 && point.minutes >= point.goalMinutes;
    final Color resolvedBarColor = goalHit
        ? widget.goalHitBarColor
        : widget.barColor;
    final double usageY = point.minutes.toDouble();
    final double goalY = math.max(usageY, point.goalMinutes.toDouble());
    final double adjustedWidth = isTouched
        ? widget.barWidth + 2
        : widget.barWidth;
    final BorderRadius rodRadius = BorderRadius.circular(adjustedWidth / 2);

    return BarChartGroupData(
      x: x,
      barRods: <BarChartRodData>[
        BarChartRodData(
          toY: usageY,
          color: resolvedBarColor,
          width: adjustedWidth,
          borderRadius: rodRadius,
          borderSide: BorderSide.none,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: goalY,
            color: widget.goalBarColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> _showingGroups(List<WeeklyUsagePoint> weeklyData) {
    return List<BarChartGroupData>.generate(7, (int index) {
      final WeeklyUsagePoint point = weeklyData[index];
      return _makeGroupData(index, point, isTouched: index == touchedIndex);
    });
  }

  BarChartData _mainBarData(List<WeeklyUsagePoint> weeklyData) {
    final double maxUsageOrGoal = weeklyData
        .map<double>(
          (WeeklyUsagePoint point) =>
              math.max(point.minutes.toDouble(), point.goalMinutes.toDouble()),
        )
        .fold<double>(40.0, math.max);

    return BarChartData(
      maxY: maxUsageOrGoal + 10,
      backgroundColor: Colors.transparent,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => widget.tooltipColor,
          tooltipHorizontalAlignment: FLHorizontalAlignment.right,
          tooltipMargin: -10,
          getTooltipItem:
              (
                BarChartGroupData group,
                int groupIndex,
                BarChartRodData rod,
                int rodIndex,
              ) {
                final WeeklyUsagePoint point = weeklyData[group.x];
                final String weekDay = _weekdayLabel(group.x);
                return BarTooltipItem(
                  '$weekDay\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${point.minutes} / ${point.goalMinutes} mins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
        ),
        touchCallback:
            (FlTouchEvent event, BarTouchResponse? barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              });
            },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: _showingGroups(weeklyData),
      gridData: const FlGridData(show: false),
    );
  }

  String _weekdayLabel(int index) {
    switch (index) {
      case 0:
        return 'Monday';
      case 1:
        return 'Tuesday';
      case 2:
        return 'Wednesday';
      case 3:
        return 'Thursday';
      case 4:
        return 'Friday';
      case 5:
        return 'Saturday';
      case 6:
        return 'Sunday';
      default:
        return '';
    }
  }

  Widget _getTitles(double value, TitleMeta meta) {
    final TextStyle style = TextStyle(
      color: widget.labelColor,
      fontWeight: FontWeight.bold,
      fontSize: widget.labelFontSize,
    );

    Widget text;
    switch (value.toInt()) {
      case 0:
        text = Text('M', style: style);
        break;
      case 1:
        text = Text('T', style: style);
        break;
      case 2:
        text = Text('W', style: style);
        break;
      case 3:
        text = Text('T', style: style);
        break;
      case 4:
        text = Text('F', style: style);
        break;
      case 5:
        text = Text('S', style: style);
        break;
      case 6:
        text = Text('S', style: style);
        break;
      default:
        text = Text('', style: style);
        break;
    }
    return SideTitleWidget(meta: meta, space: 16, child: text);
  }
}
