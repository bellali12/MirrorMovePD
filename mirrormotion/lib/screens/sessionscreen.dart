import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
// import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:mirrormotion/size_config.dart';

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
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool isConnected = false;

  @override
  void initState() {
    super.initState();

    if (!isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final connected = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const ConnectionPopUp();
          },
        );
        if (mounted && (connected ?? false)) {
          setState(() => isConnected = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 150,
                onPressed: () {},
                icon: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFF8B7D7D),
                  size: 100,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DifficultyButton(
                    level: 1,
                    color: const Color.fromARGB(255, 161, 175, 176),
                  ),
                  DifficultyButton(
                    level: 2,
                    color: const Color.fromARGB(255, 136, 153, 157),
                  ),
                  DifficultyButton(
                    level: 3,
                    color: const Color.fromARGB(255, 111, 125, 126),
                  ),
                  DifficultyButton(
                    level: 4,
                    color: const Color.fromARGB(255, 85, 98, 99),
                  ),
                  DifficultyButton(
                    level: 5,
                    color: const Color.fromARGB(255, 67, 77, 79),
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

class DifficultyButton extends StatefulWidget {
  const DifficultyButton({super.key, required this.level, required this.color});

  final int level;
  final Color color;

  @override
  State<DifficultyButton> createState() => _DifficultyButtonState();
}

class _DifficultyButtonState extends State<DifficultyButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: SizeConfig.horizontal! * 15,
      height: SizeConfig.horizontal! * 15,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(0),
          backgroundColor: widget.color,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();
          // send out a signal for the companion desktop app
        },
        child: Text(
          widget.level.toString(),
          style: TextStyle(
            fontSize: SizeConfig.horizontal! * 6,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ConnectionPopUp extends StatefulWidget {
  const ConnectionPopUp({super.key});

  @override
  State<ConnectionPopUp> createState() => _ConnectionPopUpState();
}

class _ConnectionPopUpState extends State<ConnectionPopUp> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _connecting = false;
  String? _error;

  // Converts a "connection code" to host:port.
  // Desktop shows Connection Code derived from IP with "192.168." removed.
  // Examples:
  //   "4.255"          -> "192.168.4.255:5003"
  //   "192.168.4.255"  -> "192.168.4.255:5003"
  //   "192.168.4.255:5003" -> unchanged
  //   "4.255:5003"     -> "192.168.4.255:5003"
  String _buildHostFromCode(String input) {
    var s = input.trim();
    if (s.isEmpty) return "";

    // Dev shortcuts (same machine / emulators)
    if (s == "localhost" || s == "127.0.0.1" || s == "10.0.2.2") {
      return s.contains(":") ? s : "$s:5003";
    }

    if (s.startsWith("http://")) s = s.substring(7);
    if (s.startsWith("https://")) s = s.substring(8);

    String host = s;
    String? port;

    final colon = s.lastIndexOf(':');
    if (colon != -1 && colon < s.length - 1) {
      host = s.substring(0, colon);
      port = s.substring(colon + 1);
    }

    // Short code like "4.23"
    final looksShort = RegExp(r'^\d{1,3}\.\d{1,3}$').hasMatch(host);
    if (looksShort) host = "192.168.$host";

    port ??= "5003";
    return "$host:$port";
  }

  Future<void> _connect() async {
    final code = _codeCtrl.text;
    final host = _buildHostFromCode(code);
    if (host.isEmpty) {
      setState(() => _error = "Enter a valid code or host.");
      return;
    }
    final hostOnly = host.split(':').first;
    if (hostOnly.endsWith(".0") || hostOnly.endsWith(".255")) {
      setState(
        () => _error = "Broadcast/network address not valid. Use the exact IP.",
      );
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      final uri = Uri.parse("http://$host/connect");
      final resp = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"code": code}),
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pop(true); // success; parent marks connected
      } else {
        setState(
          () => _error = "Failed (${resp.statusCode}). Check code and Wi‑Fi.",
        );
      }
    } catch (e) {
      setState(() => _error = "Could not reach desktop. Ensure same Wi‑Fi.");
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_connecting && _codeCtrl.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text("Enter connection code"),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeCtrl,
              enabled: !_connecting,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "e.g. 4.255 or 192.168.4.255",
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (canSubmit) _connect();
              },
            ),
            const SizedBox(height: 12),
            if (_connecting) const CircularProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _connecting ? null : () {},
              child: const Text(
                "Don't have the desktop app? Click to download.",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Color.fromARGB(255, 6, 70, 122),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _connecting ? null : () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: canSubmit ? _connect : null,
          child: const Text("Connect"),
        ),
      ],
    );
  }
}
