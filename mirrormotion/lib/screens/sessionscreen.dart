import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

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
        child: Chewie(
          controller: ChewieController(
            videoPlayerController: VideoPlayerController.asset(
              widget.videoPath,
            ),
            aspectRatio: 16 / 9,
            autoPlay: true,
            looping: true,
          ),
        ),
      ),
    );
  }
}
