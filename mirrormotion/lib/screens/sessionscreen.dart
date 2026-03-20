import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:audio_visualizer/visualizers/multi_wave_visualizer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
// import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:mirrormotion/size_config.dart';
import 'package:mirrormotion/services/data.dart';
import 'package:url_launcher/url_launcher.dart';

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

// TODO: poll the server periodically to check connection status

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, this.initialSongData});

  final Map<String, dynamic>? initialSongData;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool isConnected = false;
  double _currentSliderValue = 0.0;
  bool _isDesktopPlaying = false;
  bool _isFetchingStatus = false;
  double _wavePhase = 0.0;
  Timer? _statusTimer;
  Timer? _waveTimer;
  final PCMVisualizer _waveVisualizer = PCMVisualizer();
  final Map<String, Map<String, dynamic>> _songsByTitle =
      <String, Map<String, dynamic>>{};
  String _currentSongTitle = 'Song Name';
  String _currentSongArtist = 'Artist Name';

  final DataService dataService = DataService();

  String _songKey(String value) {
    return value.trim().toLowerCase();
  }

  void _seedSongInfoFromSelection() {
    final title = widget.initialSongData?['title']?.toString().trim();
    final artist = widget.initialSongData?['artist']?.toString().trim();

    if (title != null && title.isNotEmpty) {
      _currentSongTitle = title;
    }
    if (artist != null && artist.isNotEmpty) {
      _currentSongArtist = artist;
    }
  }

  Future<void> _loadSongLibrary() async {
    try {
      final songs = await dataService.getSongs();
      for (final song in songs) {
        final title = song['title']?.toString().trim();
        if (title == null || title.isEmpty) {
          continue;
        }
        _songsByTitle[_songKey(title)] = Map<String, dynamic>.from(song);
      }

      final knownArtist = _songsByTitle[_songKey(_currentSongTitle)]?['artist']
          ?.toString()
          .trim();
      if (mounted && knownArtist != null && knownArtist.isNotEmpty) {
        setState(() {
          _currentSongArtist = knownArtist;
        });
      }
    } catch (e) {
      print('Error loading songs: $e');
    }
  }

  String _resolveSongTitle(Map<String, dynamic> currentSong) {
    final statusTitle = currentSong['title']?.toString().trim();
    if (statusTitle != null && statusTitle.isNotEmpty) {
      return statusTitle;
    }
    return _currentSongTitle;
  }

  String _resolveSongArtist(Map<String, dynamic> currentSong, String title) {
    final statusArtist = currentSong['artist']?.toString().trim();
    if (statusArtist != null && statusArtist.isNotEmpty) {
      return statusArtist;
    }

    final knownArtist = _songsByTitle[_songKey(title)]?['artist']
        ?.toString()
        .trim();
    if (knownArtist != null && knownArtist.isNotEmpty) {
      return knownArtist;
    }

    return _currentSongArtist;
  }

  void _setWavePlaying(bool playing) {
    if (playing) {
      if (_waveTimer != null) {
        return;
      }
      _feedWaveFrame();
      _waveTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
        _feedWaveFrame();
      });
      return;
    }

    _waveTimer?.cancel();
    _waveTimer = null;
    _waveVisualizer.reset();
  }

  void _feedWaveFrame() {
    final pcm = Int16List(1024);
    for (int i = 0; i < pcm.length; i++) {
      final double wave =
          math.sin(_wavePhase + i * 0.12) * 0.7 +
          math.sin(_wavePhase * 0.55 + i * 0.05) * 0.3;
      final double envelope =
          0.55 + 0.45 * math.sin(_wavePhase * 0.4 + i * 0.01).abs();
      final int amplitude = (wave * 18000 * envelope).round();
      pcm[i] = amplitude.clamp(-32768, 32767).toInt();
    }
    _wavePhase += 0.32;
    _waveVisualizer.feed(Uint8List.view(pcm.buffer));
  }

  Future<void> _syncDesktopStatus() async {
    if (_isFetchingStatus || dataService.desktopAppUrl.isEmpty) {
      if (dataService.desktopAppUrl.isEmpty) {
        _setWavePlaying(false);
      }
      return;
    }

    _isFetchingStatus = true;
    final url = Uri.parse('${dataService.desktopAppUrl}/status');
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            isConnected = false;
            _isDesktopPlaying = false;
          });
        }
        _setWavePlaying(false);
        return;
      }

      final payload = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
      final connected = payload['connected'] == true;
      final currentSong = payload['currentSong'] is Map
          ? Map<String, dynamic>.from(payload['currentSong'] as Map)
          : <String, dynamic>{};
      final title = _resolveSongTitle(currentSong);
      final artist = _resolveSongArtist(currentSong, title);
      final isPlaying = connected && currentSong['playing'] == true;

      if (mounted) {
        setState(() {
          isConnected = connected;
          _isDesktopPlaying = isPlaying;
          _currentSongTitle = title;
          _currentSongArtist = artist;
        });
      }
      _setWavePlaying(isPlaying);
    } catch (e) {
      print('Error checking connection: $e');
      if (mounted) {
        setState(() {
          isConnected = false;
          _isDesktopPlaying = false;
        });
      }
      _setWavePlaying(false);
    } finally {
      _isFetchingStatus = false;
    }
  }

  Future<void> sendCommandToDesktop(String command) async {
    final url = Uri.parse('${dataService.desktopAppUrl}/command');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'command': command}),
      );
      if (response.statusCode == 200) {
        print('Command sent successfully: $command');
        Timer(const Duration(milliseconds: 300), () {
          _syncDesktopStatus();
        });
      } else {
        print('Failed to send command. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _seedSongInfoFromSelection();
    _loadSongLibrary();

    if (!isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final connected = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return ConnectionPopUp(initialSongData: widget.initialSongData);
          },
        );
        if (mounted && (connected ?? false)) {
          setState(() => isConnected = true);
          _syncDesktopStatus();
        }
      });
    }

    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _syncDesktopStatus();
    });
    _syncDesktopStatus();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _waveTimer?.cancel();
    _waveVisualizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          /*
          Purpose: send command to the desktop app to:
          - change the proportion between the reference and user view (e.g. 70/30, 50/50, 30/70)
          - aspect ratio must be preserved so shrinking one view will enlarge the other view (handled on the desktop app, here we just issue the command)
           */
          IconButton(
            icon: const Icon(Icons.palette_rounded),
            onPressed: () {
              // Open a Dialog with the three proportion options (70/30, 50/50, 30/70)
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ProportionPopUp(
                    onProportionSelected: (value) {
                      sendCommandToDesktop("change_proportion:$value");
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: SizeConfig.horizontal! * 80,
                height: SizeConfig.vertical! * 18,
                child: Card(
                  color: const Color.fromARGB(255, 246, 233, 230),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: SizeConfig.vertical! * 4,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(45, 139, 125, 125),
                              ),
                              child: ListenableBuilder(
                                listenable: _waveVisualizer,
                                builder: (context, child) {
                                  return MultiWaveVisualizer(
                                    input: _waveVisualizer.value.waveform,
                                    backgroundColor: Colors.transparent,
                                    color: _isDesktopPlaying
                                        ? const Color(0xFF5E7478)
                                        : const Color(0xFFB7AEB1),
                                    gap: 2,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _currentSongTitle,
                          style: TextStyle(
                            fontSize: SizeConfig.horizontal! * 5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF312A2D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentSongArtist,
                          style: TextStyle(
                            fontSize: SizeConfig.horizontal! * 3.8,
                            color: const Color(0xFF6A5E63),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          _isDesktopPlaying
                              ? 'Playing on desktop companion'
                              : (isConnected
                                    ? 'Paused on desktop companion'
                                    : 'Waiting for desktop companion'),
                          style: TextStyle(
                            fontSize: SizeConfig.horizontal! * 3,
                            color: const Color(0xFF8B7D7D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: Container()),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 150,
                    onPressed: () {
                      sendCommandToDesktop("prev_session");
                    },
                    icon: const Icon(
                      Icons.fast_rewind_rounded,
                      color: Color(0xFF8B7D7D),
                      size: 100,
                    ),
                  ),
                  IconButton(
                    iconSize: 150,
                    onPressed: () {
                      sendCommandToDesktop("play_session");
                    },
                    icon: const Icon(
                      Icons.play_circle_fill_rounded, // TODO toggle icon
                      color: Color(0xFF8B7D7D),
                      size: 100,
                    ),
                  ),
                  IconButton(
                    iconSize: 150,
                    onPressed: () {
                      sendCommandToDesktop("next_session");
                    },
                    icon: const Icon(
                      Icons.fast_forward_rounded,
                      color: Color(0xFF8B7D7D),
                      size: 100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volume_down_rounded,
                    color: Color.fromARGB(255, 139, 129, 129),
                  ),
                  SizedBox(
                    width: SizeConfig.horizontal! * 65,
                    child: CupertinoSlider(
                      key: const Key('slider'),
                      value: _currentSliderValue,
                      // This allows the slider to jump between divisions.
                      // If null, the slide movement is continuous.
                      // divisions: 5,
                      // The maximum slider value
                      max: 100,
                      activeColor: Color.fromARGB(255, 139, 129, 129),
                      thumbColor: Color.fromARGB(255, 139, 129, 129),
                      // This is called when sliding is started.
                      onChangeStart: (double value) {},
                      // This is called when sliding has ended.
                      onChangeEnd: (double value) {
                        setState(() {
                          sendCommandToDesktop("set_volume:$value");
                        });
                      },
                      // This is called when slider value is changed.
                      onChanged: (double value) {
                        setState(() {
                          _currentSliderValue = value;
                        });
                      },
                    ),
                  ),
                  Icon(
                    Icons.volume_up_rounded,
                    color: Color.fromARGB(255, 139, 129, 129),
                  ),
                ],
              ),
              GridView(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                shrinkWrap: true,
                padding: const EdgeInsets.all(80),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
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
                  DifficultyButton(
                    level: 6,
                    color: const Color.fromARGB(255, 67, 77, 79),
                  ),
                  DifficultyButton(
                    level: 7,
                    color: const Color.fromARGB(255, 67, 77, 79),
                  ),
                  DifficultyButton(
                    level: 8,
                    color: const Color.fromARGB(255, 67, 77, 79),
                  ),
                  DifficultyButton(
                    level: 9,
                    color: const Color.fromARGB(255, 67, 77, 79),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: (isConnected)
          ? null
          : FloatingActionButton(
              backgroundColor: Color(0xFF8B7D7D),
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return ConnectionPopUp(
                      initialSongData: widget.initialSongData,
                    );
                  },
                ).then((connected) {
                  if (mounted && (connected ?? false)) {
                    setState(() => isConnected = true);
                  }
                });
              },
              child: const Icon(
                Icons.connected_tv_rounded,
                color: Colors.white,
                size: 30,
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
  DataService dataService = DataService();
  Future<void> sendCommandToDesktop(String command) async {
    final url = Uri.parse('${dataService.desktopAppUrl}/command');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'command': command}),
      );
      if (response.statusCode == 200) {
        print('Command sent successfully: $command');
      } else {
        print('Failed to send command. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending command: $e');
    }
  }

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
          sendCommandToDesktop("change_difficulty:${widget.level}");
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
  const ConnectionPopUp({super.key, this.initialSongData});

  final Map<String, dynamic>? initialSongData;

  @override
  State<ConnectionPopUp> createState() => _ConnectionPopUpState();
}

class _ConnectionPopUpState extends State<ConnectionPopUp> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _connecting = false;
  String? _error;

  DataService dataService = DataService();

  // url launcher helper
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Converts a "connection code" to host:port.
  // Desktop shows Connection Code derived from IP with "192.168." removed.
  // Examples:
  //   "4.255"          -> "192.168.4.255:5003"
  //   "192.168.4.255"  -> "192.168.4.255:5003"
  //   "192.168.4.255:5003" -> unchanged
  //   "4.255:5003"     -> "192.168.4.255:5003"
  List<String> _buildHostFromCode(String input) {
    var s = input.trim();
    if (s.isEmpty) return [];

    // Dev shortcuts (same machine / emulators)
    if (s == "localhost" || s == "127.0.0.1" || s == "10.0.2.2") {
      return [s.contains(":") ? s : "$s:5003"];
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
    String originalHost = "";
    String altHost = "";
    if (looksShort) {
      originalHost = "192.168.$host";
      altHost = "10.100.$host";
    }

    port ??= "5003";
    return ["$originalHost:$port", "$altHost:$port"];
  }

  Future<void> _connect() async {
    final code = _codeCtrl.text;
    final host = _buildHostFromCode(code);
    if (host.isEmpty) {
      setState(() => _error = "Enter a valid code or host.");
      return;
    }
    final hostOnly = host[0].split(':').first;
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

    print("Host types: ${host[0]}, ${host[1]}");

    try {
      final uri = Uri.parse("http://${host[0]}/connect");
      final resp = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"code": code}),
          )
          .timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        if (!mounted) return;
        dataService.desktopAppUrl = "http://${host[0]}";
        final initialRequestOk = await sendInitialSongRequest();
        print("initial request $initialRequestOk");
        if (!mounted) return;
        Navigator.of(context).pop(true); // success; parent marks connected
      } else {
        // Attempt the altHost
        final altUri = Uri.parse("http://${host[1]}/connect");
        final altResp = await http
            .post(
              altUri,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"code": code}),
            )
            .timeout(const Duration(seconds: 5));
        if (altResp.statusCode == 200) {
          if (!mounted) return;
          dataService.desktopAppUrl = "http://${host[1]}";
          final initialRequestOk = await sendInitialSongRequest();
          print("initial request $initialRequestOk");
          if (!mounted) return;
          Navigator.of(context).pop(true); // success; parent marks connected
          return;
        }

        setState(
          () =>
              _error = "Failed (${altResp.statusCode}). Check code and Wi-Fi.",
        );
      }
    } catch (e) {
      print("Original attempt failed, trying alt host: $e");
      final altUri = Uri.parse("http://${host[1]}/connect");
      final altResp = await http.post(
        altUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"code": code}),
      );
      if (altResp.statusCode == 200) {
        if (!mounted) return;

        dataService.desktopAppUrl = "http://${host[1]}";
        final initialRequestOk = await sendInitialSongRequest();
        print("initial request $initialRequestOk");
        if (!mounted) return;
        Navigator.of(context).pop(true); // success; parent marks connected
        return;
      }

      setState(
        () => _error = "Failed (${altResp.statusCode}). Check code and Wi-Fi.",
      );
      setState(() => _error = "Could not reach desktop. Ensure same Wi-Fi. $e");
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<bool> sendInitialSongRequest() async {
    final uri = Uri.parse("${dataService.desktopAppUrl}/song_data");

    if (widget.initialSongData == null) {
      return false;
    }

    try {
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(widget.initialSongData),
      );
      if (resp.statusCode == 200) {
        print("Initial song data retrieved successfully.");
        return true;
      } else {
        print("Failed to retrieve song data. Status code: ${resp.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error retrieving song data: $e");
      return false;
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
            Text(
              "Desktop app is required for dance sessions. Once downloaded, it will display the connection code.",
            ),
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
              onPressed: _connecting
                  ? null
                  : () {
                      _launchURL(
                        "https://sites.google.com/view/mirrormovepd/home",
                      );
                    },
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

// Proportion Dialog (triggered by palette icon in the app bar)
class ProportionPopUp extends StatelessWidget {
  const ProportionPopUp({super.key, this.onProportionSelected});
  final Function(String)? onProportionSelected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Proportion"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("70% Instructor / 30% User"),
            onTap: () {
              if (onProportionSelected != null) {
                onProportionSelected!("70/30");
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("50% Instructor / 50% User"),
            onTap: () {
              if (onProportionSelected != null) {
                onProportionSelected!("50/50");
              }
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("30% Instructor / 70% User"),
            onTap: () {
              if (onProportionSelected != null) {
                onProportionSelected!("30/70");
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
