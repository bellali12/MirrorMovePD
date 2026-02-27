import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mirrormotion/screens/homescreen.dart';
import 'package:mirrormotion/screens/signupscreen.dart';
import 'package:mirrormotion/services/auth.dart';
import 'package:mirrormotion/services/data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Initial extends StatelessWidget {
  const Initial({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = Auth().user;

    if (user == null) {
      return const SignupScreen();
    }
    // else {
    //   return const HomeScreen();
    // }

    print("User ID: ${user.uid}");
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var userData = snapshot.data!.data();
          // DataService().userData = userData!;
          print('User Data: $userData');

          Map<String, dynamic> userDataMap = userData as Map<String, dynamic>;

          DataService().userData = userDataMap;

          if (userDataMap.containsKey('onboardingComplete') &&
              userDataMap['onboardingComplete'] == true) {
            return const HomeScreen();
          } else {
            // TODO: for now just continue to home screen until onboarding is implemented
            return const HomeScreen();

            // If onboarding is not complete, navigate to the onboarding screen
            // return const Scaffold(
            //   body: Center(child: Text('Please complete onboarding')),
            // );
          }

          // return const HomeScreen();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
