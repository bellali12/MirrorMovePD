// import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
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
  late final ConfettiController _confettiController;
  bool _hasCelebratedCompletion = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    dataService.addListener(_onUserDataChanged);
    _triggerConfettiIfComplete();
  }

  void _onUserDataChanged() {
    if (!mounted) {
      return;
    }
    _triggerConfettiIfComplete();
    setState(() {});
  }

  void _triggerConfettiIfComplete() {
    final double progress = dataService.getTodayProgressSnapshot().percent;
    final bool isComplete = progress >= 1.0;

    if (isComplete && !_hasCelebratedCompletion) {
      _hasCelebratedCompletion = true;
      _confettiController.play();
      return;
    }

    if (!isComplete) {
      _hasCelebratedCompletion = false;
    }
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
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                emissionFrequency: 0.08,
                numberOfParticles: 24,
                gravity: 0.18,
                minimumSize: const Size(6, 6),
                maximumSize: const Size(12, 12),
                colors: const [
                  Color(0xFF88999D),
                  Color(0xFFF6E9E6),
                  Color(0xFFFFD5D5),
                  Color(0xFF5E7478),
                ],
                createParticlePath: (Size size) {
                  return Path()
                    ..addOval(Rect.fromCircle(center: Offset.zero, radius: size.width / 2));
                },
              ),
            ),
            Column(
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
              ],
            ),
            if (progress >= 1.0)
              Align(
                alignment: const Alignment(0, 0.9),
                child: Text(
                  "You did it!",
                  style: TextStyle(
                    color: const Color(0xFF5E7478),
                    fontWeight: FontWeight.bold,
                    fontSize: math.max(18, SizeConfig.horizontal! * 4.6),
                  ),
                ),
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
    _confettiController.dispose();
    dataService.removeListener(_onUserDataChanged);
    super.dispose();
  }
}
