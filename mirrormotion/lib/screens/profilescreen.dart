import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mirrormotion/services/auth.dart';
import 'package:mirrormotion/size_config.dart';
import 'package:wheel_picker/wheel_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final now = TimeOfDay.now();
  late final _hoursWheel = WheelPickerController(
    itemCount: 12,
    initialIndex: now.hour % 12,
  );
  late final _minutesWheel = WheelPickerController(
    itemCount: 60,
    initialIndex: now.minute,
    mounts: [_hoursWheel],
  );

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 26.0, height: 1.5);
    final wheelStyle = WheelPickerStyle(
      itemExtent: textStyle.fontSize! * textStyle.height!, // Text height
      squeeze: 1.25,
      diameterRatio: .8,
      surroundingOpacity: .25,
      magnification: 1.2,
    );

    Widget itemBuilder(BuildContext context, int index) {
      return Text("$index".padLeft(2, '0'), style: textStyle);
    }

    final timeWheels = <Widget>[
      for (final wheelController in [_hoursWheel, _minutesWheel])
        Expanded(
          child: WheelPicker(
            builder: itemBuilder,
            controller: wheelController,
            looping: wheelController == _minutesWheel,
            style: wheelStyle,
            selectedIndexColor: const Color.fromARGB(255, 255, 222, 222),
            onIndexChanged: (index, interactionType) {
              HapticFeedback.lightImpact();
            },
          ),
        ),
    ];
    timeWheels.insert(1, const Text(":", style: textStyle));

    return Scaffold(
      backgroundColor: const Color(0xFF8B7D7D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ), // TODO: the appbar color is still slightly off from background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Pick your goal time",
              style: TextStyle(
                fontSize: 28,
                color: const Color.fromARGB(255, 255, 222, 222),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              width: SizeConfig.horizontal! * 100,
              height: SizeConfig.vertical! * 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [...timeWheels, const SizedBox(width: 6.0)],
                ),
              ),
            ),
            SizedBox(
              width: SizeConfig.horizontal! * 65,
              height: SizeConfig.vertical! * 7,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                onPressed: () {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 40.0),
              child: Divider(thickness: 5),
            ),
            SizedBox(
              width: SizeConfig.horizontal! * 65,
              height: SizeConfig.vertical! * 7,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Auth().logout().then((_) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (Route<dynamic> route) => false,
                    );
                  });
                },
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: SizeConfig.horizontal! * 65,
              height: SizeConfig.vertical! * 7,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: Text(
                  'Delete Account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Auth().deleteAccount().then((_) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (Route<dynamic> route) => false,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hoursWheel.dispose();
    _minutesWheel.dispose();
    super.dispose();
  }
}
