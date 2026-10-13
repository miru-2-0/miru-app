import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:miru/app/l10n/l10n_extension.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../extension/data/extension_manager.dart';
import '../../extension/domain/models/extension_models.dart';
import '../../media_detail/domain/models/media_detail.dart';
import '../../search/domain/models/media_item.dart';
import 'widgets/player_common.dart';
import 'widgets/player_controls.dart';
import 'widgets/player_dialogs.dart';
import 'widgets/player_hud.dart';
import 'widgets/player_sidebar.dart';

/// 仿照最新版 Kazumi (Predidit/Kazumi v2.3.6) 的全屏播放器：
/// 顶栏（返回 + 单行标题 + 更多菜单）、底栏 transport bar
/// （audio_video_progress_bar 进度条 + 倍速 / 视频比例 / 选集面板）、
/// 顶部居中 HUD（快进回退 / 倍速 / 音量亮度）、右侧锁定按钮。
///
/// 界面区块拆分在 widgets/ 下：player_hud / player_controls /
/// player_sidebar / player_dialogs，本文件只保留播放器状态与手势逻辑。
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
  late final Player _player = Player(
    configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
  );
  late final VideoController _videoController = VideoController(_player);

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _bufferSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<bool>? _completedSubscription;

  late int _currentEpisodeIndex;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = true;
  bool _hasError = false;
  String _errorMessage = '';

  // 控制栏
  bool _showControls = true;
  Timer? _hideTimer;
  double _playbackSpeed = 1.0;

  // 锁定 / 更多选项
  bool _lockPanel = false;
  int _aspectRatioIndex = 0;
  String _currentMediaUrl = '';

  // 手势
  Duration _previewPosition = Duration.zero;
  bool _showSeekHud = false;
  bool _showSpeedHud = false;
  bool _showVolumeHud = false;
  bool _showBrightnessHud = false;
  bool _adjustingBrightness = false;
  bool _verticalAdjusting = false;
  double _preciseVolume = -1;
  double _lastSpeedBeforeLongPress = 1.0;
  double _currentBrightness = 1.0;
  double _currentVolume = 0.8;
  double? _systemVolumeBeforePlayback;
  DateTime? _lastVolumeWrite;
  Timer? _hudTimer;

  /// 桌面端走 media_kit 内部音量，移动端控制系统音量（退出后还原）。
  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  // 消息胶囊
  bool _showPillToast = false;
  String _pillToastText = '';
  Timer? _pillTimer;

  // 选集面板
  bool _sidebarOpen = false;
  final ScrollController _episodeScrollController = ScrollController();

  String get _currentEpisodeName =>
      widget.episodes.isNotEmpty &&
          _currentEpisodeIndex >= 0 &&
          _currentEpisodeIndex < widget.episodes.length
      ? widget.episodes[_currentEpisodeIndex].name
      : '正片';

  double get _displaySpeed =>
      _showSpeedHud ? kPlayerLongPressSpeed : _playbackSpeed;

  /// 顶栏 / 底栏菜单所需的状态与回调
  PlayerMenuActions get _menuActions => PlayerMenuActions(
    currentSpeed: _playbackSpeed,
    aspectRatioIndex: _aspectRatioIndex,
    onSpeedChanged: _setSpeed,
    onAspectRatioChanged: _setAspectRatio,
    onShowVideoInfo: _showVideoInfoDialog,
    onMenuOpen: _onMenuOpen,
    onMenuClose: _onMenuClose,
  );

  @override
  void initState() {
    super.initState();
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _previewPosition = Duration.zero;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _listenPlayerStreams();
    _initVolume();
    _syncBrightnessFromSystem();
    _playEpisode(_currentEpisodeIndex);
    _updateTimer();
  }

  /// 读取当前系统/应用亮度作为手势调节的起始值（不支持时静默忽略）。
  Future<void> _syncBrightnessFromSystem() async {
    try {
      final value = await ScreenBrightness().application;
      if (mounted) {
        setState(() {
          _currentBrightness = value.clamp(0.0, 1.0);
        });
      }
    } catch (_) {
      // 平台不支持屏幕亮度控制时忽略，回退到默认值。
    }
  }

  /// 应用亮度（0.0 ~ 1.0），平台不支持时静默忽略。
  Future<void> _applyBrightness(double value) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(
        value.clamp(0.0, 1.0),
      );
    } catch (_) {
      // 忽略不支持亮度的平台（如 Linux）。
    }
  }

  /// 初始化音量：桌面端使用播放器内部音量；移动端接管系统音量。
  void _initVolume() {
    if (_isDesktop) {
      _player.setVolume(_currentVolume * 100);
      return;
    }
    _initSystemVolume();
  }

  Future<void> _initSystemVolume() async {
    try {
      final value = await FlutterVolumeController.getVolume();
      if (value != null) {
        // 记住进入播放器前的系统音量，退出时还原。
        _systemVolumeBeforePlayback = value.clamp(0.0, 1.0);
        if (mounted) {
          setState(() {
            _currentVolume = _systemVolumeBeforePlayback!;
          });
        }
      }
    } catch (_) {
      // 平台不支持系统音量时忽略。
    }
    try {
      // 用播放器内 HUD 代替系统音量面板。
      await FlutterVolumeController.updateShowSystemUI(false);
      FlutterVolumeController.addListener(
        _onSystemVolumeChanged,
        category: AudioSessionCategory.playback,
        emitOnStart: false,
      );
    } catch (_) {}
  }

  /// 系统音量被外部（系统按键）改变时同步到手势基准值并提示。
  void _onSystemVolumeChanged(double volume) {
    if (!mounted || _verticalAdjusting) return;
    // 忽略自己写入系统音量后回调的量化值，避免手势松手时回弹。
    final last = _lastVolumeWrite;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(milliseconds: 600)) {
      return;
    }
    setState(() {
      _currentVolume = volume.clamp(0.0, 1.0);
      _showVolumeHud = true;
      _showBrightnessHud = false;
    });
    _endAdjustment();
  }

  /// 应用音量（0.0 ~ 1.0）：桌面端写播放器，移动端写系统音量。
  void _applyVolume(double value) {
    final v = value.clamp(0.0, 1.0);
    if (_isDesktop) {
      _player.setVolume(v * 100);
    } else {
      _lastVolumeWrite = DateTime.now();
      FlutterVolumeController.setVolume(v).catchError((_) {});
    }
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

    _completedSubscription = _player.stream.completed.listen((completed) {
      if (!completed || !mounted) return;
      if (_currentEpisodeIndex < widget.episodes.length - 1) {
        _changeEpisode(_currentEpisodeIndex + 1);
      } else {
        _showPillToastMsg(context.l10n.playbackCompleted);
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
    _completedSubscription?.cancel();
    _hideTimer?.cancel();
    _pillTimer?.cancel();
    _hudTimer?.cancel();
    _episodeScrollController.dispose();
    _player.dispose();

    // 恢复系统亮度，避免退出播放器后仍停留在调节值。
    ScreenBrightness().resetApplicationScreenBrightness().catchError((_) {});

    // 移动端解除系统音量监听、还原进入前的系统音量并恢复系统音量面板。
    if (!_isDesktop) {
      try {
        FlutterVolumeController.removeListener();
        final original = _systemVolumeBeforePlayback;
        if (original != null) {
          FlutterVolumeController.setVolume(original).catchError((_) {});
        }
        FlutterVolumeController.updateShowSystemUI(true);
      } catch (_) {}
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
      final manager = ExtensionManager.instance;
      final runtime = widget.mediaItem.extensionKey != null
          ? manager.runtimeForStorageKey(widget.mediaItem.extensionKey!)
          : null;
      final resolved =
          runtime ?? manager.runtimeForPackage(widget.mediaItem.package);
      if (resolved == null) {
        throw StateError('未找到扩展 [${widget.mediaItem.package}]，无法解析播放地址');
      }

      final watch = await resolved.watch(epUrl);
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

      _currentMediaUrl = watch.url.trim();
      await _player.open(Media(_currentMediaUrl, httpHeaders: watch.headers));
      await _player.setRate(_playbackSpeed);
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

  // ---------- 控制栏显隐（对齐 Kazumi：4s 自动隐藏 + hold 机制） ----------

  int _panelHolds = 0;
  int _openMenus = 0;

  bool get _canHidePanel => _panelHolds == 0 && _openMenus == 0;

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (!_canHidePanel) return;
    _hideTimer = Timer(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      _hideControls();
    });
  }

  void _updateTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
    setState(() {
      _showControls = true;
    });
    _startHideTimer();
  }

  void _hideControls() {
    if (!_canHidePanel) return;
    _hideTimer?.cancel();
    _hideTimer = null;
    setState(() {
      _showControls = false;
    });
  }

  void _acquirePanelHold() {
    _panelHolds++;
    _hideTimer?.cancel();
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
  }

  void _releasePanelHold() {
    if (_panelHolds > 0) _panelHolds--;
    _startHideTimer();
  }

  // 菜单打开/关闭（MenuAnchor onOpen/onClose）

  void _onMenuOpen() {
    setState(() {
      _openMenus++;
    });
    _acquirePanelHold();
  }

  void _onMenuClose() {
    setState(() {
      if (_openMenus > 0) _openMenus--;
    });
    _releasePanelHold();
  }

  void _toggleVideoController() {
    if (_showControls) {
      _hideControls();
      return;
    }
    _updateTimer();
  }

  void _togglePlayPause() {
    _player.playOrPause();
  }

  void _onNextEpisodePress() {
    if (_currentEpisodeIndex < widget.episodes.length - 1) {
      _changeEpisode(_currentEpisodeIndex + 1);
      return;
    }
    _showPillToastMsg(context.l10n.alreadyLastEpisode);
  }

  void _changeEpisode(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.episodes.length) return;
    setState(() {
      _currentEpisodeIndex = newIndex;
    });
    _playEpisode(newIndex);
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _player.setRate(speed);
  }

  void _setAspectRatio(int index) {
    setState(() {
      _aspectRatioIndex = index;
    });
  }

  void _toggleLock() {
    setState(() {
      _lockPanel = !_lockPanel;
    });
    // 锁定/解锁后控制栏照常 4s 自动隐藏（锁定按钮随之隐藏）
    _updateTimer();
  }

  void _toggleSidebar() {
    final open = !_sidebarOpen;
    setState(() {
      _sidebarOpen = open;
    });
    if (open) {
      _jumpToCurrentEpisode();
    }
  }

  void _closeSidebar() {
    setState(() {
      _sidebarOpen = false;
    });
  }

  void _handleEpisodeSelect(int index) {
    _closeSidebar();
    _changeEpisode(index);
  }

  void _jumpToCurrentEpisode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_episodeScrollController.hasClients) return;
      // 每项固定 64px（卡片 margin 4 + 内容高 56）
      final target = (_currentEpisodeIndex * 64).toDouble();
      _episodeScrollController.jumpTo(
        target.clamp(0.0, _episodeScrollController.position.maxScrollExtent),
      );
    });
  }

  void _showPillToastMsg(
    String text, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _pillTimer?.cancel();
    setState(() {
      _showPillToast = true;
      _pillToastText = text;
    });
    _pillTimer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _showPillToast = false;
        });
      }
    });
  }

  void _showVideoInfoDialog() {
    showVideoInfoDialog(
      context,
      title: widget.mediaItem.title,
      episodeName: _currentEpisodeName,
      mediaUrl: _currentMediaUrl,
      onCopied: () => _showPillToastMsg(context.l10n.copiedToClipboard),
    );
  }

  void _retryCurrentEpisode() {
    setState(() {
      _hasError = false;
    });
    _playEpisode(_currentEpisodeIndex);
  }

  // ---------- 手势层 ----------

  void _endLongPress() {
    if (_lockPanel) return;
    setState(() {
      _showSpeedHud = false;
    });
    _player.setRate(_lastSpeedBeforeLongPress);
  }

  void _endAdjustment() {
    _hudTimer?.cancel();
    _verticalAdjusting = false;
    _hudTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _showVolumeHud = false;
          _showBrightnessHud = false;
        });
      }
    });
    setState(() {});
  }

  Widget _buildGestureLayer() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Positioned.fill(
      left: 16,
      top: 25,
      right: 15,
      bottom: 15,
      child: Listener(
        onPointerSignal: (event) {
          if (event is! PointerScrollEvent || _lockPanel) return;
          _hudTimer?.cancel();
          setState(() {
            _currentVolume = (_currentVolume - event.scrollDelta.dy / 20).clamp(
              0.0,
              1.0,
            );
            _showVolumeHud = true;
            _showBrightnessHud = false;
          });
          _applyVolume(_currentVolume);
          _endAdjustment();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_lockPanel) {
              // 锁定状态下点按仅临时呼出锁定按钮（随后自动隐藏）
              _updateTimer();
              return;
            }
            _toggleVideoController();
          },
          onDoubleTap: () {
            if (_lockPanel) return;
            _togglePlayPause();
          },
          onLongPressStart: (_) {
            if (_lockPanel) return;
            setState(() {
              _lastSpeedBeforeLongPress = _playbackSpeed;
              _showSpeedHud = true;
            });
            _player.setRate(kPlayerLongPressSpeed);
          },
          onLongPressEnd: (_) => _endLongPress(),
          onLongPressCancel: () => _endLongPress(),
          onHorizontalDragStart: (_) {
            if (_lockPanel) return;
            setState(() {
              _previewPosition = _position;
              _showSeekHud = true;
            });
          },
          onHorizontalDragUpdate: (details) {
            if (_lockPanel) return;
            final scale = 180000 / screenWidth;
            // 在上一帧预览值上累加，避免只用单帧 delta 导致回弹。
            final target =
                _previewPosition +
                Duration(milliseconds: (details.delta.dx * scale).round());
            final targetMs = _duration.inMilliseconds > 0
                ? target.inMilliseconds.clamp(0, _duration.inMilliseconds)
                : target.inMilliseconds;
            setState(() {
              _previewPosition = Duration(milliseconds: targetMs);
            });
          },
          onHorizontalDragEnd: (_) {
            if (_lockPanel) return;
            _player.seek(_previewPosition);
            setState(() {
              _showSeekHud = false;
            });
          },
          onHorizontalDragCancel: () {
            if (_lockPanel) return;
            setState(() {
              _showSeekHud = false;
            });
          },
          onVerticalDragStart: (details) {
            if (_lockPanel) return;
            _hudTimer?.cancel();
            _preciseVolume = _currentVolume;
            setState(() {
              _adjustingBrightness = details.localPosition.dx < screenWidth / 2;
              _verticalAdjusting = true;
              _showVolumeHud = !_adjustingBrightness;
              _showBrightnessHud = _adjustingBrightness;
            });
          },
          onVerticalDragUpdate: (details) {
            if (_lockPanel) return;
            final delta = details.delta.dy;
            if (_adjustingBrightness) {
              // 与 Kazumi 一致：整屏高度约对应 50% 亮度变化。
              final level = screenHeight * 2;
              final brightness = (_currentBrightness - delta / level).clamp(
                0.0,
                1.0,
              );
              _currentBrightness = brightness;
              _applyBrightness(brightness);
              setState(() {});
            } else {
              // 与 Kazumi 一致：累加写入 _preciseVolume，避免只用单帧 delta
              // 计算导致松手/回拉时数值回弹。level = 高度 * 3 等价于
              // Kazumi 的 0~100 刻度（整屏高度约 33%）。
              final level = screenHeight * 3;
              _preciseVolume = (_preciseVolume - delta / level).clamp(0.0, 1.0);
              _currentVolume = _preciseVolume;
              _applyVolume(_preciseVolume);
              setState(() {});
            }
          },
          onVerticalDragEnd: (_) => _endAdjustment(),
          onVerticalDragCancel: () => _endAdjustment(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  // ---------- HUD ----------

  Widget _buildHudLayer() {
    return PlayerHudLayer(
      seekVisible: _showSeekHud && !_lockPanel,
      speedVisible: _showSpeedHud && !_lockPanel,
      adjustmentVisible: (_showVolumeHud || _showBrightnessHud) && !_lockPanel,
      position: _position,
      previewPosition: _previewPosition,
      duration: _duration,
      displaySpeed: _displaySpeed,
      adjustmentType: _showBrightnessHud
          ? PlayerAdjustmentHudType.brightness
          : PlayerAdjustmentHudType.volume,
      value: _showBrightnessHud ? _currentBrightness : _currentVolume,
      adjustmentDisableAnimations: _verticalAdjusting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width <
        MediaQuery.textScalerOf(context).scale(600);
    final menus = _menuActions;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkTheme = isDark
        ? Theme.of(context)
        : ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
              brightness: Brightness.dark,
            ),
          );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Theme(
        data: darkTheme,
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. media_kit 解码渲染视图
              Video(
                controller: _videoController,
                controls: NoVideoControls,
                fit: PlayerAspectRatio.values[_aspectRatioIndex].fit,
              ),

              // 2. 顶部居中 HUD
              _buildHudLayer(),

              // 3. 手势层
              _buildGestureLayer(),

              // 4. 中间状态
              PlayerCenterOverlay(
                hasError: _hasError,
                errorMessage: _errorMessage,
                buffering: _isBuffering,
                onRetry: _retryCurrentEpisode,
              ),

              // 5. 左下角消息胶囊
              if (_showPillToast) PlayerPillToast(text: _pillToastText),

              // 6. 底栏
              PlayerBottomControls(
                visible: _showControls && !_lockPanel,
                compact: compact,
                position: _position,
                duration: _duration,
                buffered: _buffered,
                isPlaying: _isPlaying,
                menus: menus,
                onTogglePlayPause: _togglePlayPause,
                onNextEpisode: _onNextEpisodePress,
                onToggleSidebar: _toggleSidebar,
                onSeek: (value) => _player.seek(value),
                onPanelAcquire: _acquirePanelHold,
                onPanelRelease: _releasePanelHold,
              ),

              // 7. 顶栏
              PlayerTopControls(
                visible: _showControls && !_lockPanel,
                compact: compact,
                title: widget.mediaItem.title,
                episodeName: _currentEpisodeName,
                menus: menus,
                onBack: () => Navigator.of(context).pop(),
              ),

              // 8. 右侧锁定（随控制栏自动隐藏；锁定时点按屏幕可临时呼出）
              PlayerRightControls(
                visible: _showControls && (!_lockPanel || !compact),
                locked: _lockPanel,
                onToggleLock: _toggleLock,
              ),

              // 9. 选集面板遮罩
              if (_sidebarOpen) PlayerSidebarOverlay(onDismiss: _closeSidebar),

              // 10. 选集面板
              PlayerSidebar(
                open: _sidebarOpen,
                episodes: widget.episodes,
                currentEpisodeIndex: _currentEpisodeIndex,
                scrollController: _episodeScrollController,
                onSelect: _handleEpisodeSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
