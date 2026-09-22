import 'dart:async';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../extension/data/extension_manager.dart';
import '../../extension/domain/models/extension_models.dart';
import '../../media_detail/domain/models/media_detail.dart';
import '../../search/domain/models/media_item.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MediaItem mediaItem;
  final MediaDetail? detail;
  final List<EpisodeItem> episodes;
  final int initialEpisodeIndex;

  const VideoPlayerScreen({
    super.key,
    required this.mediaItem,
    this.detail,
    required this.episodes,
    this.initialEpisodeIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // media_kit 核心播放器与控制器
  late final Player _player = Player(
    configuration: const PlayerConfiguration(
      bufferSize: 32 * 1024 * 1024,
    ),
  );
  late final VideoController _videoController = VideoController(_player);

  // 播放器状态流订阅
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _bufferSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;

  late int _currentEpisodeIndex;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = true;
  bool _hasError = false;
  String _errorMessage = '';

  // UI 控制状态
  bool _showControls = true;
  Timer? _hideTimer;
  double _playbackSpeed = 1.0;

  // 手势 Toast 状态
  bool _showSeekToast = false;
  String _seekToastText = '';
  bool _showGestureToast = false;
  String _gestureToastText = '';
  IconData _gestureToastIcon = Icons.volume_up;
  bool _isLongPressFastForward = false;

  double _volumeLevel = 0.8;
  double _brightnessLevel = 0.8;

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;

    // 纯全屏横屏模式：隐藏状态栏与导航栏，锁定横屏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _listenPlayerStreams();
    _playEpisode(_currentEpisodeIndex);
  }

  void _listenPlayerStreams() {
    _positionSubscription = _player.stream.position.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _durationSubscription = _player.stream.duration.listen((dur) {
      if (mounted) {
        setState(() {
          _duration = dur;
        });
      }
    });

    _bufferSubscription = _player.stream.buffer.listen((buf) {
      if (mounted) {
        setState(() {
          _buffered = buf;
        });
      }
    });

    _playingSubscription = _player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });

    _bufferingSubscription = _player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() {
          _isBuffering = buffering;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _bufferSubscription?.cancel();
    _playingSubscription?.cancel();
    _bufferingSubscription?.cancel();

    _hideTimer?.cancel();
    _player.dispose();

    // 退出播放器即刻还原系统 UI 与竖屏模式
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  Future<void> _playEpisode(int index) async {
    setState(() {
      _isBuffering = true;
      _hasError = false;
      _errorMessage = '';
    });

    if (index < 0 || index >= widget.episodes.length) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _hasError = true;
          _errorMessage = '未找到对应的剧集播放地址';
        });
      }
      return;
    }

    final ep = widget.episodes[index];
    final epUrl = ep.url.trim();

    if (epUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _hasError = true;
          _errorMessage = '该剧集未提供有效的播放链接';
        });
      }
      return;
    }

    try {
      // 严格走 JS 扩展的 watch() 解出真实播放地址与请求头，不做任何直连兜底
      final runtime =
          ExtensionManager.instance.runtimeFor(widget.mediaItem.package);
      if (runtime == null) {
        throw StateError('未找到扩展 [${widget.mediaItem.package}]，无法解析播放地址');
      }

      final watch = await runtime.watch(epUrl);
      if (watch == null || watch.url.trim().isEmpty) {
        throw StateError('扩展未返回有效的播放地址');
      }
      if (watch.type == ExtensionWatchBangumiType.torrent) {
        if (mounted) {
          setState(() {
            _isBuffering = false;
            _hasError = true;
            _errorMessage = '当前扩展返回的是 BT 磁力资源，暂不支持播放';
          });
        }
        return;
      }

      await _player.open(Media(watch.url.trim(), httpHeaders: watch.headers));
      await _player.setRate(_playbackSpeed);
      _startHideControlsTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _hasError = true;
          _errorMessage = '视频播放异常：$e';
        });
      }
    }
  }

  void _startHideControlsTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
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
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    _player.playOrPause();
    if (_isPlaying) {
      _hideTimer?.cancel();
      setState(() {
        _showControls = true;
      });
    } else {
      _startHideControlsTimer();
    }
  }

  void _seekRelative(Duration duration) {
    final targetPosition = _position + duration;
    _player.seek(targetPosition);
    _startHideControlsTimer();

    final isForward = duration.inSeconds > 0;
    setState(() {
      _showSeekToast = true;
      _seekToastText = isForward
          ? '快进 ${duration.inSeconds.abs()} 秒'
          : '快退 ${duration.inSeconds.abs()} 秒';
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSeekToast = false;
        });
      }
    });
  }

  void _changeEpisode(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.episodes.length) return;
    setState(() {
      _currentEpisodeIndex = newIndex;
    });
    _playEpisode(newIndex);
  }

  /// 全屏模式下的“选集”右侧滑出抽屉 Panel
  void _showEpisodeDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '选集',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 340,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.94),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题与关闭按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.playlist_play,
                              color: primaryColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            '选集 (${widget.episodes.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  const SizedBox(height: 8),

                  // 剧集网格列表
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: widget.episodes.length,
                      itemBuilder: (context, index) {
                        final ep = widget.episodes[index];
                        final isCurrent = index == _currentEpisodeIndex;

                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.of(context).pop();
                            _changeEpisode(index);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? primaryColor.withValues(alpha: 0.25)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? primaryColor
                                    : Colors.white12,
                                width: isCurrent ? 1.5 : 1.0,
                              ),
                            ),
                            child: Text(
                              ep.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isCurrent ? primaryColor : Colors.white70,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  /// 全屏模式下的“倍速”右侧滑出抽屉 Panel
  void _showSpeedSelector(BuildContext context) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final primaryColor = Theme.of(context).colorScheme.primary;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '倍速',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.94),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题与关闭按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.speed, color: primaryColor, size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            '播放倍速',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 16),
                  const SizedBox(height: 8),

                  // 倍速选项列表
                  Expanded(
                    child: ListView.separated(
                      itemCount: speeds.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final speed = speeds[index];
                        final isSelected = _playbackSpeed == speed;

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _playbackSpeed = speed;
                            });
                            _player.setRate(speed);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.25)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${speed}x ${speed == 1.0 ? "(正常)" : ""}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.white,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded,
                                      color: primaryColor, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEpName = widget.episodes.isNotEmpty
        ? widget.episodes[_currentEpisodeIndex].name
        : '正片';

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onDoubleTapDown: (details) {
          final screenWidth = context.size?.width ?? 300;
          final dx = details.localPosition.dx;
          if (dx < screenWidth / 2) {
            _seekRelative(const Duration(seconds: -10));
          } else {
            _seekRelative(const Duration(seconds: 10));
          }
        },
        onVerticalDragUpdate: (details) {
          final screenWidth = context.size?.width ?? 300;
          final dx = details.localPosition.dx;
          final delta = details.primaryDelta ?? 0;

          if (dx < screenWidth / 2) {
            // 左侧滑动调节亮度
            setState(() {
              _brightnessLevel =
                  (_brightnessLevel - delta / 200).clamp(0.0, 1.0);
              _gestureToastIcon = Icons.brightness_6;
              _gestureToastText = '亮度 ${(_brightnessLevel * 100).toInt()}%';
              _showGestureToast = true;
            });
          } else {
            // 右侧滑动调节音量
            setState(() {
              _volumeLevel = (_volumeLevel - delta / 200).clamp(0.0, 1.0);
              _gestureToastIcon = Icons.volume_up;
              _gestureToastText = '音量 ${(_volumeLevel * 100).toInt()}%';
              _showGestureToast = true;
            });
          }
        },
        onVerticalDragEnd: (_) {
          Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                _showGestureToast = false;
              });
            }
          });
        },
        onLongPressStart: (_) {
          _player.setRate(2.0);
          setState(() {
            _isLongPressFastForward = true;
          });
        },
        onLongPressEnd: (_) {
          _player.setRate(_playbackSpeed);
          setState(() {
            _isLongPressFastForward = false;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. media_kit 纯全屏解码渲染视图
            Video(
              controller: _videoController,
              controls: NoVideoControls,
            ),

            // 2. 缓冲中与错误提示
            if (_isBuffering && !_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 12),
                    const Text(
                      '视频缓冲中...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (_hasError)
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _playEpisode(_currentEpisodeIndex),
                        icon: const Icon(Icons.refresh,
                            color: Colors.white, size: 18),
                        label: const Text('重试',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. 快进退 Toast
            if (_showSeekToast)
              Positioned(
                top: 25,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _seekToastText,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),

            // 4. 音量/亮度手势 Toast
            if (_showGestureToast)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_gestureToastIcon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        _gestureToastText,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

            // 5. 长按 2.0x 倍速播放 Toast
            if (_isLongPressFastForward)
              Positioned(
                top: 25,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fast_forward,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '倍速播放 2.0x',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 6. 全屏控制面板 Overlay
            if (_showControls) ...[
              // 顶部控制栏 (返回键、影视名与集数、选集按键)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.mediaItem.title} - $currentEpName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showEpisodeDrawer(context),
                        icon: const Icon(Icons.playlist_play,
                            color: Colors.white, size: 20),
                        label: const Text(
                          '选集',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 中央控制区 (快退 10s / 播放暂停 / 快进 10s)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      iconSize: 32,
                      icon: const Icon(Icons.replay_10_rounded,
                          color: Colors.white),
                      onPressed: () =>
                          _seekRelative(const Duration(seconds: -10)),
                    ),
                    const SizedBox(width: 28),
                    IconButton(
                      constraints: const BoxConstraints(
                          minWidth: 56, minHeight: 56),
                      padding: EdgeInsets.zero,
                      iconSize: 56,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: primaryColor,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 28),
                    IconButton(
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      iconSize: 32,
                      icon: const Icon(Icons.forward_10_rounded,
                          color: Colors.white),
                      onPressed: () =>
                          _seekRelative(const Duration(seconds: 10)),
                    ),
                  ],
                ),
              ),

              // 底部控制栏
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 高质 ProgressBar
                      ProgressBar(
                        progress: _position,
                        buffered: _buffered,
                        total: _duration,
                        progressBarColor: primaryColor,
                        baseBarColor: Colors.white24,
                        bufferedBarColor: Colors.white38,
                        thumbColor: primaryColor,
                        thumbRadius: 6.0,
                        timeLabelTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        onSeek: (duration) {
                          _player.seek(duration);
                        },
                      ),

                      // 底部功能按键
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 上集 / 下集 切换
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.skip_previous,
                                    color: Colors.white, size: 22),
                                tooltip: '上一集',
                                onPressed: _currentEpisodeIndex > 0
                                    ? () => _changeEpisode(
                                        _currentEpisodeIndex - 1)
                                    : null,
                              ),
                              IconButton(
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.skip_next,
                                    color: Colors.white, size: 22),
                                tooltip: '下一集',
                                onPressed: _currentEpisodeIndex <
                                        widget.episodes.length - 1
                                    ? () => _changeEpisode(
                                        _currentEpisodeIndex + 1)
                                    : null,
                              ),
                            ],
                          ),

                          // 倍速按键
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => _showSpeedSelector(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                '${_playbackSpeed}x',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
