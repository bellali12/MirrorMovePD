import 'package:mirrormotion/screens/homescreen.dart';
import 'package:mirrormotion/screens/loginscreen.dart';
import 'package:mirrormotion/screens/signupscreen.dart';
import 'package:mirrormotion/screens/sessionscreen.dart';

var routes = {
  '/': (context) => const HomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/session': (context) => const SessionScreen(),
};
