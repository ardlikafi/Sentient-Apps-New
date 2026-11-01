import 'package:provider/provider.dart';
import 'package:sentient/core/providers/user_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:sentient/core/services/youtube_stream_service.dart';
import 'package:sentient/core/services/simulated_order_service.dart';
import 'package:sentient/core/widgets/simulated_order_widgets.dart';

const Color kDarkBlue = Color(0xFF000A26);
const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

const Color kAppBarGradientStart = Color(0xFF000A26);
const Color kAppBarGradientMid = Color(0xFF001759);
const Color kAppBarGradientEnd = Color(0xFF00207B);

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    final hours = d.inHours.toString();
    return '$hours:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final String? videoId;
  final bool autoPlay;

  const CourseDetailScreen({
    super.key,
    required this.course,
    this.videoId,
    this.autoPlay = false,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isLoadingStream = false;
  bool _isFullscreen = false;
  bool _isExitingFullscreen = false;
  String? _currentVideoId;
  int _activeLessonIndex = -1; // -1 for main course video, 0..n for lessons
  bool _hasBought = false;
  bool _isBookmarked = false;

  // Custom Controls State
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaybackRunning = true;
  StreamSubscription? _orderSubscription;

  bool get _isAccountPremium {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      return userProvider.isPremium || SimulatedOrderService.isPremium;
    } catch (_) {
      return SimulatedOrderService.isPremium;
    }
  }

  @override
  void initState() {
    super.initState();
    _initVideoId();
    _orderSubscription = SimulatedOrderService.orderStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _initVideoId() {
    if (widget.videoId != null && widget.videoId!.isNotEmpty) {
      _currentVideoId = YoutubeStreamService.extractVideoId(widget.videoId!);
    } else {
      final String? url = widget.course['youtube_url'] as String?;
      if (url != null && url.isNotEmpty) {
        _currentVideoId = YoutubeStreamService.extractVideoId(url);
      }
    }

    // Fallback to first lesson video if course video is not found
    if (_currentVideoId == null) {
      final lessons = widget.course['lessons'];
      if (lessons is List && lessons.isNotEmpty) {
        final first = lessons.first;
        if (first is Map && first['youtube_url'] != null) {
          _currentVideoId = YoutubeStreamService.extractVideoId(first['youtube_url'].toString());
        }
      }
    }
  }

  void _startPlayer(String videoId, int lessonIndex) async {
    if (_currentVideoId == videoId && _videoController != null && _isPlaying) {
      return;
    }

    _hideControlsTimer?.cancel();
    _videoController?.removeListener(_onVideoControllerUpdate);
    final oldController = _videoController;
    _videoController = null;
    await oldController?.pause();
    oldController?.dispose();

    setState(() {
      _currentVideoId = videoId;
      _activeLessonIndex = lessonIndex;
      _isPlaying = true;
      _isLoadingStream = true;
      _showControls = true;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });

    try {
      final streamUri = await YoutubeStreamService.getDirectStreamUri(videoId);
      if (!mounted) return;

      if (streamUri == null) {
        setState(() {
          _isLoadingStream = false;
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to extract video stream. Please check connection.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final controller = VideoPlayerController.networkUrl(streamUri);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      controller.addListener(_onVideoControllerUpdate);
      await controller.play();

      setState(() {
        _videoController = controller;
        _isLoadingStream = false;
        _totalDuration = controller.value.duration;
        _isPlaybackRunning = controller.value.isPlaying;
      });

      _startHideTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStream = false;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load video: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onVideoControllerUpdate() {
    if (!mounted || _videoController == null) return;
    final val = _videoController!.value;
    setState(() {
      _currentPosition = val.position;
      _totalDuration = val.duration;
      _isPlaybackRunning = val.isPlaying;
    });
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    if (_isPlaybackRunning) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    _startHideTimer();
  }

  void _seekTo(double seconds) {
    if (_videoController == null) return;
    _videoController!.seekTo(Duration(seconds: seconds.toInt()));
    _startHideTimer();
  }

  void _seekRelative(int seconds) {
    if (_videoController == null) return;
    final maxSec = _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 999999;
    final newSec = (_currentPosition.inSeconds + seconds).clamp(0, maxSec);
    _seekTo(newSec.toDouble());
  }

  void _stopPlayer() {
    _isFullscreen = false;
    _isExitingFullscreen = false;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _hideControlsTimer?.cancel();
    _videoController?.removeListener(_onVideoControllerUpdate);
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _isPlaying = false;
      _isLoadingStream = false;
    });
  }

  void _toggleFullscreen() {
    final nextFullscreen = !_isFullscreen;
    setState(() {
      _isFullscreen = nextFullscreen;
      _showControls = true;
      if (!nextFullscreen) {
        _isExitingFullscreen = true;
      } else {
        _isExitingFullscreen = false;
      }
    });
    _startHideTimer();

    if (nextFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _getCurrentPlayingTitle() {
    final lessons = widget.course['lessons'];
    if (_activeLessonIndex >= 0 && lessons is List && _activeLessonIndex < lessons.length) {
      return lessons[_activeLessonIndex]['title']?.toString() ?? widget.course['title'] ?? 'Course Lesson';
    }
    return widget.course['title'] ?? 'Full Course Video';
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hideControlsTimer?.cancel();
    _videoController?.removeListener(_onVideoControllerUpdate);
    _videoController?.dispose();
    super.dispose();
  }

  void _openPaywall() async {
    final res = await PremiumPaywallDialog.show(context);
    if (mounted) {
      setState(() {});
      if (res == true || _isAccountPremium) {
        // Auto-play the course video right away since they just unlocked it!
        if (!_isPlaying && _currentVideoId != null) {
          _startPlayer(_currentVideoId!, -1);
        }
      }
    }
  }

  Widget _buildThumbnailWidget(String? url, String? videoId) {
    if (videoId != null && videoId.isNotEmpty) {
      return Image.network(
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAssetOrFallbackImage(url),
      );
    }
    return _buildAssetOrFallbackImage(url);
  }

  Widget _buildAssetOrFallbackImage(String? url) {
    if (url != null && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F172A)),
      );
    } else if (url != null && url.isNotEmpty) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F172A)),
      );
    }
    return Container(color: const Color(0xFF0F172A));
  }

  Widget _buildVideoPlayer(BuildContext context, {required bool isFullscreenMode}) {
    final double maxSec = _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds.toDouble() : 1.0;
    final double curSec = _currentPosition.inSeconds.toDouble().clamp(0.0, maxSec);

    return Container(
      width: double.infinity,
      height: isFullscreenMode ? double.infinity : null,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Native Hardware-Accelerated Video Player Canvas (or Loading Indicator)
            if (_isLoadingStream)
              Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Loading video stream...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_videoController != null && _videoController!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio > 0
                      ? _videoController!.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              Container(color: Colors.black),

            // 2. Invisible Touch Layer - ALWAYS active so tapping anywhere toggles controls
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),

            // 3. Custom Clean Video Controls Overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.82),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    top: isFullscreenMode,
                    bottom: isFullscreenMode,
                    left: isFullscreenMode,
                    right: isFullscreenMode,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = !isFullscreenMode || constraints.maxHeight < 280;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isFullscreenMode ? 16 : 8,
                            vertical: isFullscreenMode ? 8 : 2,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Header: Title + Close / Back button + HD badge
                              Row(
                                children: [
                                  if (isFullscreenMode) ...[
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                                      onPressed: _toggleFullscreen,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      _getCurrentPlayingTitle(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isFullscreenMode ? 14 : 12,
                                        fontWeight: FontWeight.bold,
                                        shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 6 : 8,
                                      vertical: isCompact ? 2 : 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.hd_rounded, color: Colors.cyanAccent, size: isCompact ? 12 : 14),
                                        const SizedBox(width: 3),
                                        Text(
                                          'HD',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isCompact ? 9 : 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isFullscreenMode) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _stopPlayer,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.close_rounded, color: Colors.white, size: 12),
                                            SizedBox(width: 3),
                                            Text(
                                              'Close',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Center Controls: Rewind 10s, Big Play/Pause, Forward 10s
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: isCompact ? 32 : 40,
                                      minHeight: isCompact ? 32 : 40,
                                    ),
                                    iconSize: isFullscreenMode ? 36 : 26,
                                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                                    onPressed: () => _seekRelative(-10),
                                  ),
                                  SizedBox(width: isFullscreenMode ? 32 : 20),
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      width: isFullscreenMode ? 58 : 44,
                                      height: isFullscreenMode ? 58 : 44,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: isCompact ? 1.5 : 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blueAccent.withValues(alpha: 0.6),
                                            blurRadius: isCompact ? 10 : 16,
                                            spreadRadius: isCompact ? 1 : 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isPlaybackRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: isFullscreenMode ? 36 : 26,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isFullscreenMode ? 32 : 20),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: isCompact ? 32 : 40,
                                      minHeight: isCompact ? 32 : 40,
                                    ),
                                    iconSize: isFullscreenMode ? 36 : 26,
                                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                                    onPressed: () => _seekRelative(10),
                                  ),
                                ],
                              ),

                              // Bottom Progress Bar: Current Time, Slider, Total Duration, Fullscreen Toggle
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(_currentPosition),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isFullscreenMode ? 12 : 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: isFullscreenMode ? 3.5 : 2.5,
                                        thumbShape: RoundSliderThumbShape(
                                          enabledThumbRadius: isFullscreenMode ? 6.0 : 4.0,
                                        ),
                                        overlayShape: RoundSliderOverlayShape(
                                          overlayRadius: isFullscreenMode ? 12 : 6,
                                        ),
                                        activeTrackColor: const Color(0xFF3B82F6),
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        value: curSec,
                                        min: 0.0,
                                        max: maxSec,
                                        onChanged: (val) {
                                          _seekTo(val);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(_totalDuration),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isFullscreenMode ? 12 : 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    icon: Icon(
                                      isFullscreenMode ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                                      color: Colors.white,
                                      size: isFullscreenMode ? 26 : 22,
                                    ),
                                    tooltip: isFullscreenMode ? 'Exit Fullscreen' : 'Landscape Fullscreen',
                                    onPressed: _toggleFullscreen,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPoster(BuildContext context, bool canPlay) {
    final price = widget.course['price'] as num? ?? 0;
    final isFree = price == 0;
    final isPremium = _isAccountPremium;

    final String? imageUrl = widget.course['imageUrl'] as String?;
    final String totalDuration = widget.course['totalDuration'] ?? 'Full Video';

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Thumbnail
            _buildThumbnailWidget(imageUrl, _currentVideoId),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Center Glowing Play Button
            Center(
              child: GestureDetector(
                onTap: () {
                  if (canPlay) {
                    if (_currentVideoId != null) {
                      _startPlayer(_currentVideoId!, -1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video is not available for this course.')),
                      );
                    }
                  } else {
                    _openPaywall();
                  }
                },
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.65),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),

            // Top Quality Badge
            Positioned(
              top: 12,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hd_rounded, color: Colors.cyanAccent, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'HD Masterclass',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Badges
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          canPlay ? Icons.touch_app_rounded : Icons.lock_rounded,
                          color: canPlay ? Colors.cyanAccent : Colors.amberAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            canPlay
                                ? (isPremium && !isFree ? '★ Unlocked' : 'Tap to Watch')
                                : 'Unlock Premium',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          totalDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final price = widget.course['price'] as num? ?? 0;
    final isFree = price == 0;
    final isPremium = _isAccountPremium;
    final canPlay = isFree || isPremium || _hasBought;

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    if (!isLandscape && _isExitingFullscreen) {
      _isExitingFullscreen = false;
    }

    // Fullscreen Landscape Immersive Player
    // Active when _isFullscreen is true, OR automatically when device is physically in landscape while playing (unless user explicitly exited)
    final bool showFullscreen = (_isFullscreen || (isLandscape && !_isExitingFullscreen)) && _isPlaying;

    if (showFullscreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _toggleFullscreen();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _buildVideoPlayer(context, isFullscreenMode: true),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kDarkBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: kPrimaryBlue.withValues(alpha: 0.5),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: const Text(
          "Course Detail",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: kPrimaryBlue.withValues(alpha: 0.5),
              child: IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isBookmarked = !_isBookmarked;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isBookmarked ? 'Saved to bookmarks' : 'Removed from bookmarks'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kAppBarGradientStart,
                kAppBarGradientMid,
                kAppBarGradientEnd,
              ],
              stops: [0.0, 0.66, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          final maxMediaHeight = isLandscape
              ? (constraints.maxHeight * 0.52).clamp(140.0, 220.0)
              : (constraints.maxWidth * 9 / 16).clamp(160.0, 280.0);

          return Column(
            children: [
              // Pinned Hero Video / Poster Player at the top
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxMediaHeight),
                child: _isPlaying
                    ? _buildVideoPlayer(context, isFullscreenMode: false)
                    : _buildHeroPoster(context, canPlay),
              ),

              // Course content & lessons outline smoothly scrollable below
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: kVeryLightBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.0),
                      topRight: Radius.circular(24.0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: _buildCourseContent(canPlay, price),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCourseContent(bool canPlay, num price) {
    final isFree = price == 0;
    final isPremium = _isAccountPremium;
    final String title = widget.course['title'] ?? 'No Title';
    final String instructorName = widget.course['instructorName'] ?? 'Sentient Grandmaster';
    final String instructorAvatar = widget.course['instructorAvatar'] ?? 'assets/images/sven.png';
    final String instructorSubtitle = widget.course['instructorSubtitle'] ?? 'Chess Coach & Master';
    final String totalDuration = widget.course['totalDuration'] ?? '0h 0m';
    final String description = widget.course['description'] ?? 'No description available.';
    final List<Map<String, dynamic>> lessons = List<Map<String, dynamic>>.from(widget.course['lessons'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kDarkBlue),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.course['category'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.course['category'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBlue,
                      ),
                    ),
                  ),
                if (price > 0 && !canPlay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade700, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, size: 14, color: Colors.amber.shade900),
                        const SizedBox(width: 4),
                        Text(
                          "Premium",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (price > 0 && canPlay)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF047857)),
                        SizedBox(width: 4),
                        Text(
                          "Unlocked",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (price == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Free",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(instructorAvatar),
              onBackgroundImageError: (e, s) => const Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructorName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kDarkBlue),
                  ),
                  Text(
                    instructorSubtitle,
                    style: TextStyle(fontSize: 14, color: kDarkBlue.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _buildInfoChip(Icons.library_books_outlined, '${lessons.isEmpty ? 1 : lessons.length} Lessons'),
            _buildInfoChip(Icons.timer_outlined, totalDuration),
            _buildInfoChip(Icons.verified_rounded, 'Verified'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          description,
          style: TextStyle(fontSize: 15, color: kDarkBlue.withValues(alpha: 0.8), height: 1.5),
        ),
        const SizedBox(height: 24),
        
        // Buy / Play Full Course Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canPlay
                ? () {
                    if (_currentVideoId != null) {
                      _startPlayer(_currentVideoId!, -1);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video is not available.')),
                      );
                    }
                  }
                : _openPaywall,
            style: ElevatedButton.styleFrom(
              backgroundColor: canPlay
                  ? (_isPlaying ? const Color(0xFF10B981) : kPrimaryBlue)
                  : Colors.amber,
              foregroundColor: canPlay ? Colors.white : kDarkBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canPlay
                      ? (_isPlaying ? Icons.play_circle_fill_rounded : Icons.play_arrow_rounded)
                      : Icons.workspace_premium_rounded,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  canPlay
                      ? (_isPlaying ? "Now Playing at Top 🎬" : (isPremium && !isFree ? "★ Play Course (Premium)" : "Play Full Course"))
                      : "Unlock with Sentient Premium",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Course Curriculum",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBlue),
            ),
            Text(
              "(${lessons.isEmpty ? 1 : lessons.length} videos)",
              style: TextStyle(fontSize: 14, color: kDarkBlue.withValues(alpha: 0.7)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (lessons.isEmpty) 
          _buildLessonItem(
            title: 'Full Course Recording',
            duration: totalDuration,
            thumbnail: widget.course['imageUrl'] ?? 'assets/images/lesson1.png',
            isLocked: !canPlay,
            isCurrentlyPlaying: _isPlaying && _activeLessonIndex == -1,
            onTap: () {
              if (canPlay) {
                if (_currentVideoId != null) {
                  _startPlayer(_currentVideoId!, -1);
                }
              } else {
                _openPaywall();
              }
            },
          ),
        if (lessons.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lessons.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final lessonUrl = lesson['youtube_url']?.toString();
              final lessonVideoId = (lessonUrl != null && lessonUrl.isNotEmpty)
                  ? YoutubeStreamService.extractVideoId(lessonUrl)
                  : _currentVideoId;
              final isLocked = !canPlay && (lesson['isLocked'] ?? true);
              final isPlayingThis = _isPlaying && _activeLessonIndex == index;

              return _buildLessonItem(
                title: lesson['title'] ?? 'Lesson ${index + 1}',
                duration: lesson['duration'] ?? 'N/A',
                thumbnail: lesson['thumbnail'] ?? (widget.course['imageUrl'] ?? 'assets/images/lesson1.png'),
                isLocked: isLocked,
                isCurrentlyPlaying: isPlayingThis,
                onTap: () {
                  if (!isLocked) {
                    if (lessonVideoId != null) {
                      _startPlayer(lessonVideoId, index);
                    }
                  } else {
                    _openPaywall();
                  }
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kLightBlue.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kPrimaryBlue, size: 16),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: kDarkBlue.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem({
    required String title,
    required String duration,
    required String thumbnail,
    required bool isLocked,
    required bool isCurrentlyPlaying,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentlyPlaying 
              ? kPrimaryBlue.withValues(alpha: 0.15) 
              : kLightBlue.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentlyPlaying ? kPrimaryBlue : Colors.transparent,
            width: isCurrentlyPlaying ? 2 : 1,
          ),
          boxShadow: isCurrentlyPlaying
              ? [
                  BoxShadow(
                    color: kPrimaryBlue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 56,
                    child: _buildThumbnailWidget(thumbnail, _currentVideoId),
                  ),
                ),
                if (isCurrentlyPlaying)
                  Container(
                    width: 80,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isCurrentlyPlaying) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: kPrimaryBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PLAYING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isCurrentlyPlaying ? kPrimaryBlue : kDarkBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 13, color: kDarkBlue.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 12,
                          color: kDarkBlue.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.amber.shade900, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "Premium",
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(
                  isCurrentlyPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  size: 18,
                ),
                label: Text(isCurrentlyPlaying ? "Playing" : "Play"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentlyPlaying ? const Color(0xFF10B981) : kPrimaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  elevation: isCurrentlyPlaying ? 0 : 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}