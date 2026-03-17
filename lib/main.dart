import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

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
  static const String _videosFolder = 'assets/videos/';
  static const Duration _controlsAutoHideAfter = Duration(seconds: 2);
  static const Duration _positionUpdateInterval = Duration(milliseconds: 250);
  static const Duration _seekStep = Duration(seconds: 10);

  List<String> _videoAssets = [];
  String? _selectedVideo;
  VideoPlayerController? _controllerSinger;
  VideoPlayerController? _controllerKaraoke;
  VideoPlayerController? _activeController;

  bool _isInitializing = true;
  String? _errorMessage;

  bool _controlsVisible = false;
  bool _lockLandscape = false;
  Timer? _hideControlsTimer;
  Timer? _positionTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadVideoAssets();
  }

  Future<void> _loadVideoAssets() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final manifestJson =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifest =
          Map<String, dynamic>.from(_parseJson(manifestJson));

      final assets = manifest.keys
          .where(
            (key) =>
                key.startsWith(_videosFolder) && key.toLowerCase().endsWith('.mp4'),
          )
          .toList()
        ..sort();

      if (assets.isEmpty) {
        setState(() {
          _videoAssets = [];
          _selectedVideo = null;
          _isInitializing = false;
          _errorMessage =
              'No video assets found in $_videosFolder.\nAdd .mp4 files and rebuild.';
        });
        return;
      }

      _videoAssets = assets;
      _selectedVideo = _selectedVideo ?? _videoAssets.first;
      await _initPlayersForVideo(_selectedVideo!);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Failed to read asset manifest.\nEnsure assets/videos/ is configured in pubspec.yaml.';
      });
    }
  }

  Map<String, dynamic> _parseJson(String source) {
    return source.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(
      // Use dart:convert's jsonDecode via a closure to avoid import noise in this snippet.
      // The import is already handled at the top of the file in your project.
      (jsonDecode(source) as Map<String, dynamic>),
    );
  }

  Future<void> _initPlayersForVideo(String assetPath) async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    _stopPositionTimer();
    _cancelHideTimer();

    await _controllerSinger?.dispose();
    await _controllerKaraoke?.dispose();

    _controllerSinger = null;
    _controllerKaraoke = null;
    _activeController = null;

    try {
      final singerController = VideoPlayerController.asset(assetPath);
      final karaokeController = VideoPlayerController.asset(assetPath);

      await Future.wait([
        singerController.initialize(),
        karaokeController.initialize(),
      ]);

      _controllerSinger = singerController;
      _controllerKaraoke = karaokeController;
      _activeController = _controllerSinger;

      setState(() {
        _isInitializing = false;
      });

      _syncPositionFromController();
      _startPositionTimer();
    } catch (e) {
      setState(() {
        _errorMessage =
            'Failed to load video from $assetPath.\nMake sure the asset file exists and is listed in pubspec.yaml.';
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _stopPositionTimer();
    _cancelHideTimer();
    _resetOrientationPreferences();
    _controllerSinger?.dispose();
    _controllerKaraoke?.dispose();
    super.dispose();
  }

  Future<void> _playActive() async {
    final controller = _activeController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    await controller.play();
    _syncPositionFromController();
    _showControlsTemporarily();
  }

  Future<void> _pauseActive() async {
    final controller = _activeController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    await controller.pause();
    _syncPositionFromController();
    _showControlsTemporarily();
  }

  void _syncPositionFromController() {
    final controller = _activeController;
    if (controller == null || !controller.value.isInitialized) return;
    final nextPosition = controller.value.position;
    final nextDuration = controller.value.duration;
    if (mounted) {
      setState(() {
        _position = nextPosition;
        _duration = nextDuration;
      });
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(_positionUpdateInterval, (_) {
      final controller = _activeController;
      if (controller == null || !controller.value.isInitialized) return;
      if (!controller.value.isPlaying && !_controlsVisible) return;
      _syncPositionFromController();
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  void _cancelHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = null;
  }

  void _showControlsTemporarily() {
    if (!mounted) return;
    setState(() {
      _controlsVisible = true;
    });
    _cancelHideTimer();
    _hideControlsTimer = Timer(_controlsAutoHideAfter, () {
      if (!mounted) return;
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  Future<void> _seekTo(Duration target) async {
    final controller = _activeController;
    if (controller == null || !controller.value.isInitialized) return;
    final dur = controller.value.duration;
    final clamped = _clampDuration(target, Duration.zero, dur);
    await controller.seekTo(clamped);
    _syncPositionFromController();
    _showControlsTemporarily();
  }

  Future<void> _seekBy(Duration delta) async {
    await _seekTo(_position + delta);
  }

  Duration _clampDuration(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  Future<void> _playNextVideo() async {
    if (_videoAssets.isEmpty || _selectedVideo == null) return;
    final currentIndex = _videoAssets.indexOf(_selectedVideo!);
    if (currentIndex < 0) return;
    final nextIndex = (currentIndex + 1) % _videoAssets.length;
    final next = _videoAssets[nextIndex];
    setState(() {
      _selectedVideo = next;
    });
    await _initPlayersForVideo(next);
    await _playActive();
  }

  Future<void> _playPreviousVideo() async {
    if (_videoAssets.isEmpty || _selectedVideo == null) return;
    final currentIndex = _videoAssets.indexOf(_selectedVideo!);
    if (currentIndex < 0) return;
    final prevIndex =
        (currentIndex - 1 + _videoAssets.length) % _videoAssets.length;
    final prev = _videoAssets[prevIndex];
    setState(() {
      _selectedVideo = prev;
    });
    await _initPlayersForVideo(prev);
    await _playActive();
  }

  Future<void> _toggleOrientationLock() async {
    final nextLockLandscape = !_lockLandscape;
    setState(() {
      _lockLandscape = nextLockLandscape;
    });

    if (nextLockLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    _showControlsTemporarily();
  }

  void _resetOrientationPreferences() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  String _formatTime(Duration d) {
    final totalSeconds = d.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _activeController;

    return Scaffold(
      appBar: _lockLandscape
          ? null
          : AppBar(
              title: const Text('Karaoke Player'),
            ),
      body: SafeArea(
        child: _lockLandscape
            ? // Fullscreen experience in landscape: only video + overlay.
            Center(
                child: _buildVideoArea(controller),
              )
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: _buildVideoArea(controller),
                    ),
                  ),
                  _buildVideoList(),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoList() {
    if (_videoAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _videoAssets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final assetPath = _videoAssets[index];
          final isSelected = assetPath == _selectedVideo;
          final displayName = assetPath.split('/').last;

          return GestureDetector(
            onTap: () async {
              if (assetPath == _selectedVideo) return;
              setState(() {
                _selectedVideo = assetPath;
              });
              await _initPlayersForVideo(assetPath);
            },
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple : Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey[700]!,
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to play',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        },
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showControlsTemporarily,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          if (!controller.value.isPlaying) _buildCenterPlayButton(),
          if (_controlsVisible) _buildOverlayControls(controller),
        ],
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          radius: 48,
          onTap: _isInitializing ? null : _playActive,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(
              Icons.play_arrow,
              size: 64,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayControls(VideoPlayerController controller) {
    final isPlaying = controller.value.isPlaying;
    final duration = _duration;
    final position = _position;
    final canSeek = duration.inMilliseconds > 0;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Column(
          children: [
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _isInitializing ? null : _playPreviousVideo,
                  iconSize: 34,
                  icon: const Icon(Icons.skip_previous),
                ),
                IconButton(
                  onPressed: _isInitializing ? null : () => _seekBy(-_seekStep),
                  iconSize: 34,
                  icon: const Icon(Icons.replay_10),
                ),
                IconButton(
                  onPressed: _isInitializing
                      ? null
                      : () => isPlaying ? _pauseActive() : _playActive(),
                  iconSize: 44,
                  icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                ),
                IconButton(
                  onPressed: _isInitializing ? null : () => _seekBy(_seekStep),
                  iconSize: 34,
                  icon: const Icon(Icons.forward_10),
                ),
                IconButton(
                  onPressed: _isInitializing ? null : _playNextVideo,
                  iconSize: 34,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: [
                  Text(_formatTime(position),
                      style: const TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: canSeek
                          ? position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble()
                          : 0,
                      max: canSeek ? duration.inMilliseconds.toDouble() : 1,
                      onChanged: _isInitializing || !canSeek
                          ? null
                          : (v) => _seekTo(Duration(milliseconds: v.round())),
                    ),
                  ),
                  Text(_formatTime(duration),
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (_selectedVideo ?? '').split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  IconButton(
                    tooltip: _lockLandscape
                        ? 'Switch to portrait'
                        : 'Switch to landscape',
                    onPressed: _toggleOrientationLock,
                    icon: Icon(
                      _lockLandscape ? Icons.stay_current_portrait : Icons.stay_current_landscape,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

