import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaraokeApp());
}

class KaraokeApp extends StatelessWidget {
  const KaraokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karaoke Player',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const KaraokePage(),
    );
  }
}

class KaraokePage extends StatefulWidget {
  const KaraokePage({super.key});

  @override
  State<KaraokePage> createState() => _KaraokePageState();
}

class _KaraokePageState extends State<KaraokePage> {
  // Adjust these paths to match where your videos are stored on the device.
  // For example: /storage/emulated/0/Download/videoA.mp4
  final String _videoSingerPath = '/storage/emulated/0/Download/videoA.mp4';
  final String _videoKaraokePath = '/storage/emulated/0/Download/videoB.mp4';

  VideoPlayerController? _controllerSinger;
  VideoPlayerController? _controllerKaraoke;
  VideoPlayerController? _activeController;

  bool _isSingerActive = true;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayers();
  }

  Future<void> _initPlayers() async {
    try {
      final singerFile = File(_videoSingerPath);
      final karaokeFile = File(_videoKaraokePath);

      if (!await singerFile.exists() || !await karaokeFile.exists()) {
        setState(() {
          _errorMessage =
              'Video files not found.\nExpected at:\n$_videoSingerPath\n$_videoKaraokePath';
          _isInitializing = false;
        });
        return;
      }

      final singerController = VideoPlayerController.file(singerFile);
      final karaokeController = VideoPlayerController.file(karaokeFile);

      await Future.wait([
        singerController.initialize(),
        karaokeController.initialize(),
      ]);

      // Start with singer video as the active one.
      _controllerSinger = singerController;
      _controllerKaraoke = karaokeController;
      _activeController = _controllerSinger;
      _isSingerActive = true;

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize videos: $e';
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controllerSinger?.dispose();
    _controllerKaraoke?.dispose();
    super.dispose();
  }

  Future<void> _playActive() async {
    final controller = _activeController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    await controller.play();
    setState(() {});
  }

  Future<void> _pauseActive() async {
    final controller = _activeController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    await controller.pause();
    setState(() {});
  }

  Future<void> _switchTo(bool singer) async {
    if (_controllerSinger == null || _controllerKaraoke == null) return;

    final current = _activeController;
    final target = singer ? _controllerSinger! : _controllerKaraoke!;

    if (current == null || current == target) {
      // Nothing to switch.
      return;
    }

    final wasPlaying = current.value.isPlaying;
    final position = current.value.position;

    // Seek the target controller to the same position.
    await target.seekTo(position);

    // Optionally keep both paused/playing state consistent.
    if (wasPlaying) {
      await current.pause();
      await target.play();
    } else {
      await target.pause();
    }

    setState(() {
      _activeController = target;
      _isSingerActive = singer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _activeController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Karaoke Player'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _buildVideoArea(controller),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitializing
                          ? null
                          : () async {
                              await _switchTo(true);
                              await _playActive();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isSingerActive ? Colors.purple : Colors.grey[800],
                      ),
                      child: const Text('Singer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitializing
                          ? null
                          : () async {
                              await _switchTo(false);
                              await _playActive();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isSingerActive
                            ? Colors.purple
                            : Colors.grey[800],
                      ),
                      child: const Text('Karaoke'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _isInitializing
                        ? null
                        : () {
                            _pauseActive();
                          },
                    icon: const Icon(Icons.pause),
                  ),
                  IconButton(
                    onPressed: _isInitializing
                        ? null
                        : () {
                            _playActive();
                          },
                    icon: const Icon(Icons.play_arrow),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea(VideoPlayerController? controller) {
    if (_isInitializing) {
      return const CircularProgressIndicator();
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'Video not initialized.\nCheck file paths and restart the app.',
        textAlign: TextAlign.center,
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}

