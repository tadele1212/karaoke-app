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
  static const String _songTitleChinese = '城里的月光';

  @override
  Widget build(BuildContext context) {
    const chengColor = Colors.black;
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
                  height: 120,
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
                              ? const Color(0xFFE0B64A)
                              : Colors.white.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const _SongTitleRichText(),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 40,
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
                                      songTitle: _songTitleChinese,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 40,
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
                                      songTitle: _songTitleChinese,
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
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: enabled ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _SongTitleRichText extends StatelessWidget {
  const _SongTitleRichText();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '城里的月光\n',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'chéng lǐ de yuè guāng\n',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: 'Moonlight in the City',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
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
  static const Duration _positionUpdateInterval = Duration(milliseconds: 250);
  static const Duration _seekStep = Duration(seconds: 10);

  List<String> _videoAssets = [];
  String? _selectedVideo;
  VideoPlayerController? _controller;

  bool _isInitializing = true;
  String? _errorMessage;

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
  }

  Future<void> _pauseActive() async {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;

    await controller.pause();
    _syncPositionFromController();
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
      _syncPositionFromController();
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> _seekTo(Duration target) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final dur = controller.value.duration;
    final clamped = _clampDuration(target, Duration.zero, dur);
    await controller.seekTo(clamped);
    _syncPositionFromController();
  }

  Future<void> _onSeekDragStart(double value) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _wasPlayingBeforeScrub = controller.value.isPlaying;
    if (_wasPlayingBeforeScrub) {
      await controller.pause();
    }
    if (!mounted) return;
    final stepMs = _toHalfSecondStepMs(value);
    setState(() {
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
                          fontSize: 32,
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
      onTap: () {},
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          _buildOverlayControls(controller),
        ],
      ),
    );
  }

  Widget _buildOverlayControls(VideoPlayerController controller) {
    final duration = _duration;
    final position = _isScrubbing ? _scrubPosition : _position;
    final canSeek = duration.inMilliseconds > 0;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Column(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: Row(
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

