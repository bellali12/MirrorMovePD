import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mirrormotion/components/chart.dart';
import 'package:mirrormotion/size_config.dart';
import 'package:mirrormotion/screens/sessionscreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String todayVideoPath = "assets/IMG_7837.MOV";
  String todayThumbnailPath = "assets/IMG_8248.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B7D7D),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 0.0,
              horizontal: SizeConfig.horizontal! * 5,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // TextField(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/profile');
                          },
                          child: CircleAvatar(),
                        ),
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
                  color: Color.fromARGB(255, 169, 189, 195),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Workout Duration",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text("See All"),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "20/60 mins",
                                    style: GoogleFonts.poppins(
                                      color: Color.fromARGB(255, 255, 211, 211),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  // Text(
                                  //   "60 mins",
                                  //   style: GoogleFonts.poppins(
                                  //     color: Color.fromARGB(255, 252, 240, 240),
                                  //     fontSize: 20,
                                  //     fontWeight: FontWeight.bold,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 200,
                                  height: 200,
                                  color: const Color.fromARGB(0, 255, 255, 255),
                                  child: BarChartWidget(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      "Daily Dance Workout",
                      style: GoogleFonts.poppins(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.favorite,
                      color: const Color.fromARGB(255, 242, 191, 215),
                    ),
                  ],
                ),
                // video thumbnail
                SizedBox(
                  // width: SizeConfig.horizontal! * 90,
                  height: SizeConfig.vertical! * 30,
                  child: InkWell(
                    onTap: () {
                      // open the session screen with the specified video
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SessionScreen(),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            todayThumbnailPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            size: 60,
                            color: const Color.fromARGB(
                              255,
                              255,
                              213,
                              213,
                            ).withValues(alpha: 0.9),
                          ),
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
