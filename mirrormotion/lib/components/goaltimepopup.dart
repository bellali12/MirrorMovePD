// import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:wheel_picker/wheel_picker.dart';
import 'package:mirrormotion/size_config.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:mirrormotion/services/data.dart';

class GoalTimePopup extends StatefulWidget {
  const GoalTimePopup({super.key});

  @override
  State<GoalTimePopup> createState() => _GoalTimePopupState();
}

class _GoalTimePopupState extends State<GoalTimePopup> {
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

  String _statusForProgress(double progress) {
    if (progress <= 0.0) {
      return "Start moving now!";
    }
    if (progress < 0.5) {
      return "Great start! Keep going!";
    }
    if (progress < 1.0) {
      return "Almost there!";
    }
    return "Daily goal complete!";
  }

  @override
  Widget build(BuildContext context) {
    final ProgressSnapshot progressSnapshot = dataService
        .getTodayProgressSnapshot();
    final double progress = progressSnapshot.percent;
    final String statusText = _statusForProgress(progress);
    final int percentLabel = (progress * 100).round();

    return AlertDialog(
      title: Text(statusText),
      content: SizedBox(
        height: SizeConfig.vertical! * 50,
        width: SizeConfig.horizontal! * 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 140.0,
              lineWidth: 33.0,
              animation: true,
              percent: progress.clamp(0.0, 1.0),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$percentLabel%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                  Text(
                    "${progressSnapshot.currentMinutes}/${progressSnapshot.goalMinutes} mins",
                    style: TextStyle(fontSize: 14.0),
                  ),
                  Text(
                    "Daily Dance Workout",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17.0,
                    ),
                  ),
                ],
              ),

              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Color(0xFF88999D),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
            // WheelPicker(
            //   builder: (context, index) => Text("$index", style: textStyle),
            //   controller: secondsWheel,
            //   selectedIndexColor: Colors.blue,
            //   onIndexChanged: (index, interactionType) =>
            //       print("On index $index"),
            //   style: WheelPickerStyle(
            //     itemExtent:
            //         textStyle.fontSize! * textStyle.height!, // Text height
            //     squeeze: 1.25,
            //     diameterRatio: .8,
            //     surroundingOpacity: .25,
            //     magnification: 1.2,
            //   ),
            // ),
            // WheelPicker(
            //   builder: (context, index) => Text("$index", style: textStyle),
            //   controller: secondsWheel,
            //   selectedIndexColor: Colors.blue,
            //   onIndexChanged: (index, interactionType) =>
            //       print("On index $index"),
            //   style: WheelPickerStyle(
            //     itemExtent:
            //         textStyle.fontSize! * textStyle.height!, // Text height
            //     squeeze: 1.25,
            //     diameterRatio: .8,
            //     surroundingOpacity: .25,
            //     magnification: 1.2,
            //   ),
            // ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            // Save the goal time
            Navigator.of(context).pop();
          },
          child: Text("Save"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    dataService.removeListener(_onUserDataChanged);
    super.dispose();
  }
}
