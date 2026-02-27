import 'package:flutter/material.dart';
import 'package:mirrormotion/services/data.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartWidget extends StatefulWidget {
  const BarChartWidget({super.key});

  @override
  State<BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  int touchedIndex = -1;
  Color barColor = Colors.white;
  Color barBackgroundColor = Colors.grey;
  final Duration animDuration = const Duration(milliseconds: 250);

  final DataService dataService = DataService();

  @override
  Widget build(BuildContext context) {
    return BarChart(mainBarData(), duration: animDuration);
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color? barColor,
    double width = 22,
    List<int> showTooltips = const [],
  }) {
    barColor ??= barColor;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: barColor,
          width: width,
          borderSide: const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<int> getUsageData() {
    Map<String, dynamic> usageData = dataService.userData;

    int todayGoal = usageData['dailyMinutes'] ?? 40;
    int todayProgress = 0;
    if (usageData.containsKey('progress')) {
      DateTime lastUpdated = DateTime.parse(
        usageData['progress']['lastUpdated'],
      );
      if (DateTime.now().difference(lastUpdated).inDays == 0) {
        todayProgress = usageData['progress']['currentMinutes'] ?? 0;
      } else {
        // TODO: reset progress if last updated is not today
      }
    }

    // If the goalChanges key exists, iterate through the timestamps
    // If the timestamp is more than a week away, ignore it
    // For each day, mark the most recent goal change to be the goal for that day
    Map<String, int> dailyGoals = {};
    if (usageData.containsKey('goalChanges')) {
      Map<String, dynamic> goalChanges =
          usageData['goalChanges']; // key is timestamp and value is goal

      for (var change in goalChanges.entries) {
        DateTime timestamp = DateTime.parse(change.key);
        if (DateTime.now().difference(timestamp).inDays <= 7) {
          String day = timestamp.weekday.toString();

          if (!dailyGoals.containsKey(day) ||
              timestamp.isAfter(DateTime.parse(dailyGoals[day]! as String))) {
            dailyGoals[day] = change.value;
          }
        }
      }
    }
    // Now we have a map of daily goals for the past week, we can use this to determine the goal for each day
    // To get the use of those days, we then check for session history and sum up the minutes for each day, then we can return a list of usage data for the past week
    List<int> usageDataList = [];
    if (usageData.containsKey('sessionHistory')) {
      Map<String, dynamic> sessionHistory = usageData['sessionHistory'];
      for (var session in sessionHistory.values) {
        DateTime startTime = DateTime.parse(session['startTime']);
        DateTime endTime = DateTime.parse(session['endTime']);
        if (DateTime.now().difference(startTime).inDays <= 7) {
          String day = startTime.weekday.toString();
          int minutes = endTime.difference(startTime).inMinutes;
          if (dailyGoals.containsKey(day)) {
            usageDataList[int.parse(day) - 1] += minutes;
          } else {
            usageDataList[int.parse(day) - 1] += minutes;
          }
        } else {
          // TODO: remove old session history
        }
      }
    }
    // Construct the return package: [day0/goal0, ..., day6/goal6, todayProgress, todayGoal]
    List<int> returnData = [];
    for (int i = 0; i < 7; i++) {
      // String day = (i + 1).toString();
      if (usageDataList.length > i) {
        returnData.add(usageDataList[i]);
      } else {
        returnData.add(0);
      }
      // if (dailyGoals.containsKey(day)) {
      //   returnData.add(dailyGoals[day]!);
      // } else {
      //   returnData.add(40);
      // }
    }

    return returnData;
  }

  List<BarChartGroupData> showingGroups() => List.generate(7, (i) {
    List<int> usageData = getUsageData();

    print(usageData);

    switch (i) {
      case 0:
        return makeGroupData(
          0,
          usageData[0] * 1.0,
          isTouched: i == touchedIndex,
        );
      case 1:
        return makeGroupData(
          1,
          usageData[1] * 1.0,
          isTouched: i == touchedIndex,
        );
      case 2:
        return makeGroupData(
          2,
          usageData[2] * 1.0,
          isTouched: i == touchedIndex,
        );
      case 3:
        return makeGroupData(
          3,
          usageData[3] * 1.0,
          isTouched: i == touchedIndex,
        );
      case 4:
        return makeGroupData(
          4,
          usageData[4] * 1.0,
          isTouched: i == touchedIndex,
        );
      case 5:
        return makeGroupData(
          5,
          usageData[5] * 1.0,
          isTouched: i == touchedIndex,
        );
      case 6:
        return makeGroupData(
          6,
          usageData[6] * 1.0,
          isTouched: i == touchedIndex,
        );
      default:
        return throw Error();
    }
  });

  BarChartData mainBarData() {
    return BarChartData(
      backgroundColor: Colors.transparent,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey,
          tooltipHorizontalAlignment: FLHorizontalAlignment.right,
          tooltipMargin: -10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String weekDay;
            switch (group.x) {
              case 0:
                weekDay = 'Monday';
                break;
              case 1:
                weekDay = 'Tuesday';
                break;
              case 2:
                weekDay = 'Wednesday';
                break;
              case 3:
                weekDay = 'Thursday';
                break;
              case 4:
                weekDay = 'Friday';
                break;
              case 5:
                weekDay = 'Saturday';
                break;
              case 6:
                weekDay = 'Sunday';
                break;
              default:
                throw Error();
            }
            return BarTooltipItem(
              '$weekDay\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: (rod.toY - 1).toString(),
                  style: const TextStyle(
                    color: Colors.white, //widget.touchedBarColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
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
      barGroups: showingGroups(),
      gridData: const FlGridData(show: false),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
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
