import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B7D7D),
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(),
              Row(
                children: [
                  CircleAvatar(),
                  Column(children: [Text('GOOD MORNING'), Text('Status')]),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications),
                  ),
                ],
              ),
              Card(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text("Daily Activity"),
                        Text("Daily Activity"),
                        Text("Daily Activity"),
                        Text("Daily Activity"),
                      ],
                    ),
                    Column(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text("See All"),
                        ),
                        Container(color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
