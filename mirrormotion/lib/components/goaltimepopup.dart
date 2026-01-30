import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wheel_picker/wheel_picker.dart';

class GoalTimePopup extends StatefulWidget {
  const GoalTimePopup({super.key});

  @override
  State<GoalTimePopup> createState() => _GoalTimePopupState();
}

class _GoalTimePopupState extends State<GoalTimePopup> {
  @override
  Widget build(BuildContext context) {
    final secondsWheel = WheelPickerController(itemCount: 10);
    const textStyle = TextStyle(fontSize: 32.0, height: 1.5);

    Timer.periodic(const Duration(seconds: 1), (_) => secondsWheel.shiftDown());

    return AlertDialog(
      title: Text("Set your daily goal time"),
      content: Container(
        height: 850,
        child: Column(
          children: [
            WheelPicker(
              builder: (context, index) => Text("$index", style: textStyle),
              controller: secondsWheel,
              selectedIndexColor: Colors.blue,
              onIndexChanged: (index, interactionType) =>
                  print("On index $index"),
              style: WheelPickerStyle(
                itemExtent:
                    textStyle.fontSize! * textStyle.height!, // Text height
                squeeze: 1.25,
                diameterRatio: .8,
                surroundingOpacity: .25,
                magnification: 1.2,
              ),
            ),
            WheelPicker(
              builder: (context, index) => Text("$index", style: textStyle),
              controller: secondsWheel,
              selectedIndexColor: Colors.blue,
              onIndexChanged: (index, interactionType) =>
                  print("On index $index"),
              style: WheelPickerStyle(
                itemExtent:
                    textStyle.fontSize! * textStyle.height!, // Text height
                squeeze: 1.25,
                diameterRatio: .8,
                surroundingOpacity: .25,
                magnification: 1.2,
              ),
            ),
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
    super.dispose();
  }
}
