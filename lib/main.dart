import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
      home: const KaraokeHomePage(),
    );
  }
}

class KaraokeHomePage extends StatefulWidget {
  const KaraokeHomePage({super.key});

  @override
  State<KaraokeHomePage> createState() => _KaraokeHomePageState();
}

class _KaraokeHomePageState extends State<KaraokeHomePage> {
  bool _chengSelected = false;

  static const String _chengAudioAsset = 'assets/videos/Cheng_li_lyrics.mp4';
  static const String _chengKaraokeAsset = 'assets/videos/Cheng_li_karaoke.mp4';

  @override
  Widget build(BuildContext context) {
    const chengColor = Color(0xFF7C4DFF);
    const audioColor = Color(0xFF2196F3);
    const karaokeColor = Color(0xFFE91E63);

    final audioEnabled = _chengSelected;
    final karaokeEnabled = _chengSelected;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 64, // shorter button height
                  child: InkWell(
                    onTap: () {
                      setState(() => _chengSelected = true);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: chengColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _chengSelected
                              ? Colors.yellowAccent
                              : Colors.white.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Text(
                        'Cheng li',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        label: 'Audio',
                        color: audioColor,
                        enabled: audioEnabled,
                        onTap: audioEnabled
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const KaraokePage(
                                      initialAssetPath: _chengAudioAsset,
                                      autoPlay: true,
                                      songTitle: 'Cheng li',
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModeButton(
                        label: 'Karaoke',
                        color: karaokeColor,
                        enabled: karaokeEnabled,
                        onTap: karaokeEnabled
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const KaraokePage(
                                      initialAssetPath: _chengKaraokeAsset,
                                      autoPlay: true,
                                      songTitle: 'Cheng li',
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final effectiveColor = enabled ? color : color.withValues(alpha: 0.35);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: enabled ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class KaraokePage extends StatefulWidget {
  const KaraokePage({
    super.key,
    this.initialAssetPath,
    this.autoPlay = false,
    required this.songTitle,
  });

  final String? initialAssetPath;
  final bool autoPlay;
  final String songTitle;

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
  VideoPlayerController? _controller;

  bool _isInitializing = true;
  String? _errorMessage;

  bool _controlsVisible = false;
  Timer? _hideControlsTimer;
  Timer? _positionTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isScrubbing = false;
  Duration _scrubPosition = Duration.zero;
  bool _wasPlayingBeforeScrub = false;
  int _lastScrubStepMs = -1;

  @override
  void initState() {
    super.initState();
    _loadVideoAssets();
    _setLandscapeOnly();
    _enterImmersiveMode();
  }

  Future<void> _setLandscapeOnly() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _enterImmersiveMode() async {
    // Hide Android system UI (navigation buttons) like normal video players.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _exitImmersiveMode() async {
    // Restore default system UI behavior when leaving the screen.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      final initialAsset = widget.initialAssetPath;
      _selectedVideo = (initialAsset != null && assets.contains(initialAsset))
          ? initialAsset
          : _videoAssets.first;
      setState(() {
        _controlsVisible = false;
      });
      await _initPlayersForVideo(_selectedVideo!);
      if (widget.autoPlay) {
        await _playActive(showControls: false);
      }
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

    await _controller?.dispose();
    _controller = null;

    try {
      final controller = VideoPlayerController.asset(assetPath);
      await controller.initialize();
      _controller = controller;

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
    _controller?.dispose();
    _exitImmersiveMode();
    super.dispose();
  }

  Future<void> _playActive({bool showControls = true}) async {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    await controller.play();
    _syncPositionFromController();
    if (showControls) {
      _showControlsTemporarily();
    }
  }

  Future<void> _pauseActive() async {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    await controller.pause();
    _syncPositionFromController();
    _showControlsTemporarily();
  }

  void _syncPositionFromController() {
    final controller = _controller;
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
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) return;
      if (_isScrubbing) return;
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
    final controller = _controller;
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

  Future<void> _onSeekDragStart(double value) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _cancelHideTimer();
    _wasPlayingBeforeScrub = controller.value.isPlaying;
    if (_wasPlayingBeforeScrub) {
      await controller.pause();
    }
    if (!mounted) return;
    final stepMs = _toHalfSecondStepMs(value);
    setState(() {
      _controlsVisible = true;
      _isScrubbing = true;
      _scrubPosition = Duration(milliseconds: stepMs);
      _position = _scrubPosition;
    });
    _lastScrubStepMs = stepMs;
  }

  void _onSeekDragUpdate(double value) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final stepMs = _toHalfSecondStepMs(value);
    if (stepMs == _lastScrubStepMs) return;
    _lastScrubStepMs = stepMs;
    final target = Duration(milliseconds: stepMs);
    if (!mounted) return;
    setState(() {
      _controlsVisible = true;
      _isScrubbing = true;
      _scrubPosition = target;
      _position = target;
    });
    // Non-blocking seek makes drag updates feel real-time.
    unawaited(controller.seekTo(target));
  }

  Future<void> _onSeekDragEnd(double value) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final target = Duration(milliseconds: _toHalfSecondStepMs(value));
    await controller.seekTo(target);
    if (_wasPlayingBeforeScrub) {
      await controller.play();
    }
    _wasPlayingBeforeScrub = false;

    if (!mounted) return;
    setState(() {
      _isScrubbing = false;
      _position = target;
    });
    _lastScrubStepMs = -1;
    _showControlsTemporarily();
  }

  int _toHalfSecondStepMs(double sliderValueMs) {
    const step = 500;
    return ((sliderValueMs / step).round()) * step;
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

  String _formatTime(Duration d) {
    final totalSeconds = d.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(child: _buildVideoArea(controller)),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  const SizedBox(width: 100),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        widget.songTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Return'),
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
          onTap: _isInitializing ? null : () => _playActive(),
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
    final position = _isScrubbing ? _scrubPosition : _position;
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
                      divisions: canSeek ? (duration.inMilliseconds / 500).floor() : null,
                      onChangeStart:
                          _isInitializing || !canSeek ? null : _onSeekDragStart,
                      onChanged:
                          _isInitializing || !canSeek ? null : _onSeekDragUpdate,
                      onChangeEnd:
                          _isInitializing || !canSeek ? null : _onSeekDragEnd,
                    ),
                  ),
                  Text(_formatTime(duration),
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

