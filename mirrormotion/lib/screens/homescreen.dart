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

  List<Map<String, dynamic>> availableSongs = [
    {'title': 'Rainbow', 'artist': 'Bella Li', 'level': 5, 'duration': '10:00'},
    {
      'title': 'Sunshine',
      'artist': 'John Doe',
      'level': 3,
      'duration': '08:30',
    },
    {
      'title': 'Starlight',
      'artist': 'Jane Smith',
      'level': 4,
      'duration': '09:15',
    },
  ];

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
                Container(
                  // width: SizeConfig.horizontal! * 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    color: const Color.fromARGB(255, 169, 189, 195),
                  ),
                  height: SizeConfig.vertical! * 10,
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
                        // ClipRRect(
                        //   borderRadius: BorderRadius.circular(20),
                        //   child: Image.asset(
                        //     todayThumbnailPath,
                        //     fit: BoxFit.cover,
                        //   ),
                        // ),
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
                SizedBox(
                  height: SizeConfig.vertical! * 30,
                  width:
                      SizeConfig.horizontal! *
                      100, //TODO: Fix horizontal padding
                  child: Card(
                    color: const Color.fromARGB(
                      255,
                      255,
                      213,
                      213,
                    ).withValues(alpha: 0.9),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Text("Pick a song to dance to"),
                          ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableSongs.length,
                            itemBuilder: (context, index) {
                              return Card(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SessionScreen(
                                          initialSongData:
                                              availableSongs[index],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              availableSongs[index]['title'],
                                              textAlign: TextAlign.left,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Level: ${availableSongs[index]['level']}",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${availableSongs[index]['artist']}",
                                            ),
                                            Text(
                                              "Duration: ${availableSongs[index]['duration']}",
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
