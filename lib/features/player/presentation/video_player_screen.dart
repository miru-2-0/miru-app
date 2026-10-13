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
      : context.l10n.mainEpisode;

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
    _currentEpisodeIndex = widget.initialEpisodeIndex.clamp(
      0,
      widget.episodes.isEmpty ? 0 : widget.episodes.length - 1,
    );

    // 锁定屏幕横屏 + 全屏隐藏系统栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initHardwareStateAndSubscriptions();
    _playEpisodeIndex(_currentEpisodeIndex);
  }

  Future<void> _initHardwareStateAndSubscriptions() async {
    // 监听播放状态
    _positionSubscription = _player.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSubscription = _player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _bufferSubscription = _player.stream.buffer.listen((buf) {
      if (mounted) setState(() => _buffered = buf);
    });
    _playingSubscription = _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _bufferingSubscription = _player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isBuffering = buffering);
    });
    _completedSubscription = _player.stream.completed.listen((completed) {
      if (completed) {
        _onNextEpisodePress();
      }
    });

    // 初始化硬件状态（亮度 / 音量）
    try {
      if (!_isDesktop) {
        final currentSysVol = await FlutterVolumeController.getVolume();
        _systemVolumeBeforePlayback = currentSysVol;
        if (currentSysVol != null) {
          _currentVolume = currentSysVol;
        }
      } else {
        _currentVolume = (_player.state.volume / 100).clamp(0.0, 1.0);
      }
    } catch (_) {}

    try {
      _currentBrightness = await ScreenBrightness().current;
    } catch (_) {
      _currentBrightness = 1.0;
    }

    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hudTimer?.cancel();
    _pillTimer?.cancel();

    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _bufferSubscription?.cancel();
    _playingSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _completedSubscription?.cancel();

    _episodeScrollController.dispose();
    _player.dispose();

    // 还原系统硬件状态
    if (!_isDesktop && _systemVolumeBeforePlayback != null) {
      FlutterVolumeController.setVolume(_systemVolumeBeforePlayback!);
    }

    // 还原系统 UI 与竖屏方向
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }

  // --- 播放控制逻辑 ---

  Future<void> _playEpisodeIndex(int index) async {
    if (index < 0 || index >= widget.episodes.length) return;

    setState(() {
      _currentEpisodeIndex = index;
      _isBuffering = true;
      _hasError = false;
      _errorMessage = '';
      _position = Duration.zero;
      _duration = Duration.zero;
      _buffered = Duration.zero;
    });

    final ep = widget.episodes[index];
    final epUrl = ep.url.trim();

    if (epUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isBuffering = false;
          _hasError = true;
          _errorMessage = context.l10n.noPlayableLink;
        });
      }
      return;
    }

    try {
      final manager = ExtensionManager.instance;
      final runtime = widget.mediaItem.extensionKey != null
          ? manager.runtimeForStorageKey(widget.mediaItem.extensionKey!)
          : null;
      final resolved =
          runtime ?? manager.runtimeForPackage(widget.mediaItem.package);
      if (resolved == null) {
        throw StateError(context.l10n.extensionNotFound(widget.mediaItem.package));
      }

      final watch = await resolved.watch(epUrl);
      if (watch == null || watch.url.trim().isEmpty) {
        throw StateError(context.l10n.noValidUrlFromExtension);
      }
      if (watch.type == ExtensionWatchBangumiType.torrent) {
        if (mounted) {
          setState(() {
            _isBuffering = false;
            _hasError = true;
            _errorMessage = context.l10n.torrentNotSupported;
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
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_hasError) return;
    _player.playOrPause();
    _updateTimer();
  }

  void _retryCurrentEpisode() {
    _playEpisodeIndex(_currentEpisodeIndex);
  }

  void _onNextEpisodePress() {
    if (_currentEpisodeIndex < widget.episodes.length - 1) {
      _showToast('正在为您切换至下一集：${widget.episodes[_currentEpisodeIndex + 1].name}');
      _playEpisodeIndex(_currentEpisodeIndex + 1);
    } else {
      _showToast('已是最后一集');
    }
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _player.setRate(speed);
    _showToast('已切换倍速至 ${speed}x');
  }

  void _setAspectRatio(int index) {
    setState(() {
      _aspectRatioIndex = index;
    });
    if (!mounted) return;
    final label = PlayerAspectRatio.values[index].getLabel(context);
    _showToast('已切换画面比例至 $label');
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
    if (_sidebarOpen) {
      _acquirePanelHold();
    } else {
      _releasePanelHold();
    }
  }

  void _showVideoInfoDialog() {
    _acquirePanelHold();
    showVideoInfoDialog(
      context,
      title: widget.mediaItem.title,
      episodeName: _currentEpisodeName,
      mediaUrl: _currentMediaUrl,
      onCopied: () => _showToast(context.l10n.mediaUrlCopied),
    ).then((_) => _releasePanelHold());
  }

  // --- 定时器与控制栏可见性管理 ---

  int _panelHolds = 0;
  bool get _canHidePanel => _panelHolds == 0;

  void _onMenuOpen() {
    _acquirePanelHold();
  }

  void _onMenuClose() {
    _releasePanelHold();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
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
    if (_panelHolds > 0) {
      _panelHolds--;
    }
    if (_canHidePanel) {
      _updateTimer();
    }
  }

  void _toggleVideoController() {
    if (_showControls) {
      _hideControls();
    } else {
      _updateTimer();
    }
  }

  void _toggleLock() {
    setState(() {
      _lockPanel = !_lockPanel;
    });
    if (_lockPanel) {
      _showToast('面板已锁定');
      _startHideTimer();
    } else {
      _showToast('面板已解锁');
      _updateTimer();
    }
  }

  void _showToast(String text) {
    _pillTimer?.cancel();
    setState(() {
      _pillToastText = text;
      _showPillToast = true;
    });
    _pillTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _showPillToast = false;
        });
      }
    });
  }

  // --- 手势与 HUD 控制 ---

  void _endLongPress() {
    if (!_showSpeedHud) return;
    setState(() {
      _showSpeedHud = false;
    });
    _player.setRate(_lastSpeedBeforeLongPress);
  }

  void _applyVolume(double volume) {
    final v = volume.clamp(0.0, 1.0);
    _currentVolume = v;
    if (_isDesktop) {
      _player.setVolume(v * 100);
    } else {
      _preciseVolume = v;
      final now = DateTime.now();
      if (_lastVolumeWrite == null ||
          now.difference(_lastVolumeWrite!).inMilliseconds > 32) {
        _lastVolumeWrite = now;
        FlutterVolumeController.setVolume(v);
      }
    }
  }

  void _applyBrightness(double brightness) {
    final b = brightness.clamp(0.0, 1.0);
    _currentBrightness = b;
    try {
      ScreenBrightness().setScreenBrightness(b);
    } catch (_) {}
  }

  void _endAdjustment() {
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showSeekHud = false;
          _showSpeedHud = false;
          _showVolumeHud = false;
          _showBrightnessHud = false;
          _verticalAdjusting = false;
        });
      }
    });
    setState(() {});
  }

  Widget _buildHudLayer() {
    final speedVisible = _showSpeedHud && !_lockPanel;
    final seekVisible = _showSeekHud && !_lockPanel;
    final adjustmentVisible =
        (_showVolumeHud || _showBrightnessHud) && !_lockPanel;

    return PlayerHudLayer(
      speedVisible: speedVisible,
      displaySpeed: _displaySpeed,
      seekVisible: seekVisible,
      position: _position,
      previewPosition: _previewPosition,
      duration: _duration,
      adjustmentVisible: adjustmentVisible,
      adjustmentType: _showBrightnessHud
          ? PlayerAdjustmentHudType.brightness
          : PlayerAdjustmentHudType.volume,
      value: _showBrightnessHud ? _currentBrightness : _currentVolume,
      adjustmentDisableAnimations: _verticalAdjusting,
    );
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
            if (_lockPanel || _duration.inMilliseconds <= 0) return;
            _hudTimer?.cancel();
            final deltaMs = (details.delta.dx * 120).toInt();
            final newMs = (_previewPosition.inMilliseconds + deltaMs).clamp(
              0,
              _duration.inMilliseconds,
            );
            setState(() {
              _previewPosition = Duration(milliseconds: newMs);
              _showSeekHud = true;
            });
          },
          onHorizontalDragEnd: (_) {
            if (_lockPanel) return;
            _player.seek(_previewPosition);
            _endAdjustment();
          },
          onVerticalDragStart: (details) {
            if (_lockPanel) return;
            _adjustingBrightness = details.globalPosition.dx < screenWidth / 2;
            _verticalAdjusting = true;
            _hudTimer?.cancel();
          },
          onVerticalDragUpdate: (details) {
            if (_lockPanel) return;
            final delta = -details.delta.dy / (screenHeight * 0.7);
            if (_adjustingBrightness) {
              _applyBrightness(_currentBrightness + delta);
              setState(() {
                _showBrightnessHud = true;
                _showVolumeHud = false;
              });
            } else {
              _applyVolume(_currentVolume + delta);
              setState(() {
                _showVolumeHud = true;
                _showBrightnessHud = false;
              });
            }
          },
          onVerticalDragEnd: (_) {
            if (_lockPanel) return;
            _endAdjustment();
          },
          child: const SizedBox.expand(),
        ),
      ),
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

              // 8. 右侧锁定按钮
              PlayerRightControls(
                visible: _showControls,
                locked: _lockPanel,
                onToggleLock: _toggleLock,
              ),

              // 9. 右侧选集面板
              if (_sidebarOpen) ...[
                PlayerSidebarOverlay(onDismiss: _toggleSidebar),
                PlayerSidebar(
                  open: _sidebarOpen,
                  episodes: widget.episodes,
                  currentEpisodeIndex: _currentEpisodeIndex,
                  scrollController: _episodeScrollController,
                  onSelect: (index) {
                    _playEpisodeIndex(index);
                    _toggleSidebar();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
