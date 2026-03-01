import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final userStream = FirebaseAuth.instance.authStateChanges();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> signup(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final int nowEpochSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int defaultDailyMinutes = 30;

      // Initialize user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
            'name': email.split('@').first,
            'dailyMinutes': defaultDailyMinutes,
            'goalChanges': {nowEpochSeconds.toString(): defaultDailyMinutes},
            'progress': {'currentMinutes': 0, 'lastUpdated': Timestamp.now()},
            'sessionHistory': {},
            'onboardingComplete': false,
          });
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .delete();

      // Delete user from Firebase Auth
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }
}
