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

/// Song id → `*_01` = audio, `*_02` = karaoke (paths under [assets/videos/]).
class _SongEntry {
  const _SongEntry({
    required this.id,
    required this.audioAsset,
    required this.karaokeAsset,
    required this.playerTitle,
    required this.titleChild,
  });

  final String id;
  final String audioAsset;
  final String karaokeAsset;
  final String playerTitle;
  final Widget titleChild;
}

class _KaraokeHomePageState extends State<KaraokeHomePage> {
  /// Selected song id; null until user picks a song.
  String? _selectedSongId;

  static const _chengAudioAsset = 'assets/videos/Cheng_li_lyrics.mp4';
  static const _chengKaraokeAsset = 'assets/videos/Cheng_li_karaoke.mp4';
  static const _songTitleChinese = '城里的月光';

  static const _gggAudioAsset = 'assets/videos/ggg_01.mp4';
  static const _gggKaraokeAsset = 'assets/videos/ggg_02.mp4';

  static const _subaruAudioAsset = 'assets/videos/Subaru_01.mp4';
  static const _subaruKaraokeAsset = 'assets/videos/Subaru_02.mp4';
  static const _subaruPlayerTitle = '昴';

  static const _bangawanAudioAsset = 'assets/videos/Bangawan_01.mp4';
  static const _bangawanKaraokeAsset = 'assets/videos/Bangawan_02.mp4';
  static const _bangawanPlayerTitle = 'Bangawan Solo';

  static final List<_SongEntry> _songs = [
    _SongEntry(
      id: 'chengli',
      audioAsset: _chengAudioAsset,
      karaokeAsset: _chengKaraokeAsset,
      playerTitle: _songTitleChinese,
      titleChild: const _SongTitleRichText(),
    ),
    _SongEntry(
      id: 'ggg',
      audioAsset: _gggAudioAsset,
      karaokeAsset: _gggKaraokeAsset,
      playerTitle: 'Quizás',
      titleChild: const _GggSongTileTitle(),
    ),
    _SongEntry(
      id: 'subaru',
      audioAsset: _subaruAudioAsset,
      karaokeAsset: _subaruKaraokeAsset,
      playerTitle: _subaruPlayerTitle,
      titleChild: const _SubaruSongTileTitle(),
    ),
    _SongEntry(
      id: 'bangawan',
      audioAsset: _bangawanAudioAsset,
      karaokeAsset: _bangawanKaraokeAsset,
      playerTitle: _bangawanPlayerTitle,
      titleChild: const _BangawanSongTileTitle(),
    ),
  ];

  _SongEntry? get _selectedSong {
    if (_selectedSongId == null) return null;
    for (final s in _songs) {
      if (s.id == _selectedSongId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const chengColor = Colors.black;
    const audioColor = Color(0xFF2196F3);
    const karaokeColor = Color(0xFFE91E63);

    final hasSelection = _selectedSong != null;
    final audioEnabled = hasSelection;
    final karaokeEnabled = hasSelection;

    void openPlayer(String assetPath) {
      final song = _selectedSong!;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KaraokePage(
            initialAssetPath: assetPath,
            autoPlay: true,
            songTitle: song.playerTitle,
          ),
        ),
      );
    }

    Future<void> openPickSong() async {
      final id = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (_) => _PickSongPage(songs: _songs),
        ),
      );
      if (!mounted || id == null) return;
      setState(() => _selectedSongId = id);
    }

    const pickColor = Color(0xFF9C27B0);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedSong != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          color: chengColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE0B64A),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _selectedSong!.titleChild,
                      ),
                    ),
                  ),
                const Spacer(),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.52,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: _buildModeButton(
                              label: 'Vocal',
                              color: audioColor,
                              enabled: audioEnabled,
                              onTap: audioEnabled
                                  ? () => openPlayer(_selectedSong!.audioAsset)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: _buildModeButton(
                              label: 'Karaoke',
                              color: karaokeColor,
                              enabled: karaokeEnabled,
                              onTap: karaokeEnabled
                                  ? () => openPlayer(_selectedSong!.karaokeAsset)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: _buildModeButton(
                              label: 'Pick song',
                              color: pickColor,
                              enabled: true,
                              onTap: openPickSong,
                            ),
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

/// Lists all catalog songs; tapping one pops with that song [id] so the home screen can set selection.
class _PickSongPage extends StatelessWidget {
  const _PickSongPage({required this.songs});

  final List<_SongEntry> songs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick song'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.black,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop<String>(song.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      song.playerTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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

/// Home tile for ggg: two lines only. [playerTitle] is `Quizás` for pick list + player overlay.
class _GggSongTileTitle extends StatelessWidget {
  const _GggSongTileTitle();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Quizás\n',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'Perhaps',
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

/// Home tile for Subaru. [playerTitle] is `昴` for pick list + player overlay.
class _SubaruSongTileTitle extends StatelessWidget {
  const _SubaruSongTileTitle();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '昴\n',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'Subaru\n',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: 'Pleiades',
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

/// Home tile for Bangawan. [playerTitle] is `Bangawan Solo` for pick list + player overlay.
class _BangawanSongTileTitle extends StatelessWidget {
  const _BangawanSongTileTitle();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Bangawan Solo\n',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'The Solo River',
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

