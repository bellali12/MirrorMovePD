import 'package:mirrormotion/initial.dart';
import 'package:mirrormotion/screens/homescreen.dart';
import 'package:mirrormotion/screens/loginscreen.dart';
import 'package:mirrormotion/screens/signupscreen.dart';
import 'package:mirrormotion/screens/profilescreen.dart';
import 'package:mirrormotion/screens/workouthistoryscreen.dart';
// import 'package:mirrormotion/screens/sessionscreen.dart';

var routes = {
  '/': (context) => const Initial(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/homescreen': (context) => const HomeScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/workout-history': (context) => const WorkoutHistoryScreen(),
  // '/session': (context) => const SessionScreen(),
};
