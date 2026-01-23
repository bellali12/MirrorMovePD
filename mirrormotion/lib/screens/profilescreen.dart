import 'package:flutter/material.dart';
import 'package:mirrormotion/services/auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Logout'),
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
            ElevatedButton(
              child: Text('Delete Account'),
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
          ],
        ),
      ),
    );
  }
}
