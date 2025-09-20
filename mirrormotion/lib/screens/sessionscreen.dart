import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

/*
  Instructor video on top and view of the user on bottom.
  - the border between the two is draggable to adjust the size of each view.
  - feedback text flashes on the screen somewhere visible
  - if the user is doing really well, the Early Complete popup shows at the bottom
    - Ready to move on to the next level?
      - Not yet/Yes
      - Not yet: resume session until the end of the video
      - Yes: go back to level select
  - before the end session popup, there will be a mini celebratory animation
  - at the end of a session, there will be a larger popup asking the following:
    - WORKOUT COMPLETE
      - close button: goes back to home screen
      - encore button: goes back to level select
      - if nothing is pressed for 10 seconds, a survey popup will show up asking for feedback
        - How challengin was this workout? (slider from 1 to 10)
        - Did you like the background music? (yes/no)
      - Sessions are clips of varying styles stitched together (Jazz, Hiphop, Tai Chi, etc).
        - based on the frequency of the styles the user chooses, we can determine what they like
  - Settings button in the top right corner:
    - opens a settings overlay:
      - Customize Figure: some kind of visual enhancement over the instructor side (TBD)
      - Go to next level: go forward to the next level
      - Go to previous level: goes back to the previous level
  - exit button in the top left corner:
    - opens a confirmation dialog:
      - Are you sure you want to exit?
        - Yes: goes back to home screen
        - No: closes dialog and returns to session
  - *Video player controls are hidden
  - audio is based on the video

  SESSION PIECE SYSTEM:
  - since sessions are a combination of multiple clips, here is what each clip needs:
    - difficulty: easy, medium, hard
    - style: jazz, hiphop, tai chi, etc.
    - duration: how long the clip is in seconds
    - video path: the path to the video file
    - list of keyframes: each keyframe is associated with a certain timestamp 
      of the clip and the idea is for the user's pose coordinates to be checked against it
  
  - What is a level:
    - duration, difficulty is universal (averaged across clips)
    - style is random, but the gentler ones are front-loaded
    - when transitioning, the user can freestyle while the system changes
 */

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.asset(widget.videoPath);
    _videoPlayerController.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Session Screen')),
      body: Center(
        child: Column(
          children: [],
        )
        // child: Chewie(
        //   controller: ChewieController(
        //     videoPlayerController: VideoPlayerController.asset(
        //       widget.videoPath,
        //     ),
        //     aspectRatio: 16 / 9,
        //     autoPlay: true,
        //     looping: true,
        //   ),
        // ),
      ),
    );
  }
}
