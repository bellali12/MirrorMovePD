import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mirrormotion/services/data.dart';

class BarChartWidget extends StatefulWidget {
  const BarChartWidget({super.key});

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  int touchedIndex = -1;
  final Color barColor = Colors.white;
  final Color goalBarColor = const Color.fromARGB(255, 109, 125, 131);
  final Duration animDuration = const Duration(milliseconds: 250);
  final DataService dataService = DataService();

  @override
  void initState() {
    super.initState();
    dataService.addListener(_onUserDataChanged);
  }

  void _onUserDataChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    dataService.removeListener(_onUserDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<WeeklyUsagePoint> weeklyData = dataService.getCurrentWeekUsage();
    return BarChart(mainBarData(weeklyData), duration: animDuration);
  }

  BarChartGroupData makeGroupData(
    int x,
    WeeklyUsagePoint point, {
    bool isTouched = false,
    double width = 22,
    List<int> showTooltips = const <int>[],
  }) {
    final bool goalHit =
        point.goalMinutes > 0 && point.minutes >= point.goalMinutes;
    final Color resolvedBarColor = goalHit
        ? const Color.fromARGB(255, 88, 198, 150)
        : barColor;
    final double usageY = point.minutes.toDouble();
    final double goalY = math.max(usageY, point.goalMinutes.toDouble());
    final double adjustedWidth = isTouched ? width + 2 : width;

    return BarChartGroupData(
      x: x,
      barRods: <BarChartRodData>[
        BarChartRodData(
          toY: usageY,
          color: resolvedBarColor,
          width: adjustedWidth,
          borderSide: BorderSide.none,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: goalY,
            color: goalBarColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingGroups(List<WeeklyUsagePoint> weeklyData) {
    return List<BarChartGroupData>.generate(7, (int index) {
      final WeeklyUsagePoint point = weeklyData[index];
      return makeGroupData(index, point, isTouched: index == touchedIndex);
    });
  }

  BarChartData mainBarData(List<WeeklyUsagePoint> weeklyData) {
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
          getTooltipColor: (_) => Colors.blueGrey,
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
            getTitlesWidget: getTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: showingGroups(weeklyData),
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

  Widget getTitles(double value, TitleMeta meta) {
    const TextStyle style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('M', style: style);
        break;
      case 1:
        text = const Text('T', style: style);
        break;
      case 2:
        text = const Text('W', style: style);
        break;
      case 3:
        text = const Text('T', style: style);
        break;
      case 4:
        text = const Text('F', style: style);
        break;
      case 5:
        text = const Text('S', style: style);
        break;
      case 6:
        text = const Text('S', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(meta: meta, space: 16, child: text);
  }
}
