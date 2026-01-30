import 'package:flutter/material.dart';
import 'package:mirrormotion/size_config.dart';
import 'package:mirrormotion/services/auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController retypePasswordController = TextEditingController();

  Future<void> _launchPrivacyPolicyURL() async {
    final Uri url = Uri.parse(
      'https://doc-hosting.flycricket.io/mirrormove-pd-privacy-policy/253a7d40-db99-4176-8b80-0ad00650b2a7/privacy',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  bool validCredentials() {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        retypePasswordController.text.isEmpty) {
      return false;
    }

    if (passwordController.text != retypePasswordController.text) {
      return false;
    }

    // valid email regex
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp emailRegex = RegExp(emailPattern);
    if (!emailRegex.hasMatch(emailController.text)) {
      return false;
    }

    if (passwordController.text.length < 6) {
      return false;
    }

    // Password requirements: at least one uppercase and lowercase letter, one number, and one special character
    String passwordPattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$';
    RegExp passwordRegex = RegExp(passwordPattern);
    if (!passwordRegex.hasMatch(passwordController.text)) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Image.asset(
                'assets/login screen.png',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
              SizedBox(height: SizeConfig.vertical! * 6),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 24.0,
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 185, 185, 185),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    fillColor: Color(0xFF897C7C),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 24.0,
                ),
                child: TextField(
                  controller: passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 185, 185, 185),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    fillColor: Color(0xFF897C7C),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 6.0, 24.0, 12.0),
                child: TextField(
                  controller: retypePasswordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Retype Password',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 185, 185, 185),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    fillColor: Color(0xFF897C7C),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              SizedBox(
                width: SizeConfig.horizontal! * 90,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 169, 189, 195),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 32.0,
                    ),
                  ),
                  onPressed: validCredentials()
                      ? () {
                          Auth()
                              .signup(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                              )
                              .then((value) {
                                Navigator.pushNamed(context, '/homescreen');
                              });
                        }
                      : null,
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      _launchPrivacyPolicyURL();
                    },
                    child: Text("Privacy Policy"),
                  ),
                  // Container(width: SizeConfig.horizontal! * 34),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text("I already have an account"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
