import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mirrormotion/components/chart.dart';

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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 0.0,
              horizontal: 30.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GOOD MORNING',
                              style: GoogleFonts.poppins(
                                color: Color(0xFFf7d9d9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Status',
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 240, 240),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Daily Activity"),
                            Text("Workout Duration"),
                            Text("20 mins/60 mins"),
                            Text("Daily Medicine Intake"),
                            Text("2/4"),
                          ],
                        ), //TODO: customize text look
                        Column(
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: const Text("See All"),
                            ),
                            Container(
                              width: 200,
                              height: 200,
                              color: Colors.white,
                              child: BarChartWidget(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
