import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../extension/data/extension_manager.dart';
import '../../extension/domain/models/extension_models.dart';
import '../../media_detail/domain/models/media_detail.dart';
import '../../search/domain/models/media_item.dart';

/// 仿照最新版 Kazumi (Predidit/Kazumi v2.3.6) 的全屏播放器：
/// 顶栏（返回 + 单行标题 + 更多菜单）、底栏 transport bar
/// （audio_video_progress_bar 进度条 + 倍速 / 视频比例 / 选集面板）、
/// 顶部居中 HUD（快进回退 / 倍速 / 音量亮度）、右侧锁定按钮。
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

enum _PlayerAspectRatio {
  automatic('自动', BoxFit.contain),
  crop('裁剪', BoxFit.cover),
  stretch('拉伸', BoxFit.fill),
  ratio4x3('4:3', BoxFit.fill);

  const _PlayerAspectRatio(this.label, this.fit);

  final String label;
  final BoxFit fit;
}

enum _TimeLabelPlacement {
  aboveProgress,
  besideProgress,
  afterPlaybackButtons;

  static _TimeLabelPlacement forViewport(Size viewport) {
    final hasRoomForSideLabels = viewport.shortestSide >= 600 &&
        viewport.shortestSide / viewport.longestSide >= 9 / 16;
    return hasRoomForSideLabels ? besideProgress : aboveProgress;
  }
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  static const double _longPressSpeed = 2.0;
  static const List<double> _speeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    2.25,
    2.5,
    2.75,
    3.0,
  ];

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
  Duration _dragSeekStart = Duration.zero;
  Duration _previewPosition = Duration.zero;
  bool _showSeekHud = false;
  bool _showSpeedHud = false;
  bool _showVolumeHud = false;
  bool _showBrightnessHud = false;
  bool _adjustingBrightness = false;
  double _preciseVolume = -1;
  double _lastSpeedBeforeLongPress = 1.0;
  double _currentBrightness = 0.8;
  double _currentVolume = 0.8;
  Timer? _hudTimer;

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
      _showSpeedHud ? _longPressSpeed : _playbackSpeed;

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
    _player.setVolume(_currentVolume * 100);
    _playEpisode(_currentEpisodeIndex);
    _updateTimer();
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
        _showPillToastMsg('播放完成');
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
      await _player.open(
        Media(_currentMediaUrl, httpHeaders: watch.headers),
      );
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
    _showPillToastMsg('已是最后一集');
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
      if (_lockPanel) {
        _showControls = false;
      } else {
        _showControls = true;
      }
    });
    _hideTimer?.cancel();
    if (_lockPanel) return;
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

  String _formatDuration(Duration d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    final hours = pad(d.inHours % 24);
    final minutes = pad(d.inMinutes % 60);
    final seconds = pad(d.inSeconds % 60);
    if (hours == '00') return '$minutes:$seconds';
    return '$hours:$minutes:$seconds';
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

  // ---------- 菜单 ----------

  static Widget _menuLabel(String label, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_rounded, size: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }

  static const MenuStyle _menuStyle = MenuStyle(
    backgroundColor: WidgetStatePropertyAll(Color(0xFF242424)),
    surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
    elevation: WidgetStatePropertyAll(6),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
  );

  Widget _anchorButton({
    required Widget child,
    required List<Widget> menuChildren,
    String? tooltip,
  }) {
    return MenuAnchor(
      style: _menuStyle,
      menuChildren: menuChildren,
      onOpen: _onMenuOpen,
      onClose: _onMenuClose,
      builder: (context, controller, _) {
        return Tooltip(
          message: tooltip ?? '',
          child: IconButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            icon: child,
          ),
        );
      },
    );
  }

  List<Widget> _speedMenuItems() {
    return [
      for (final speed in _speeds)
        MenuItemButton(
          onPressed: () => _setSpeed(speed),
          child: _menuLabel('${speed}x', selected: _playbackSpeed == speed),
        ),
    ];
  }

  List<Widget> _aspectRatioMenuItems() {
    return [
      for (final (int index, _PlayerAspectRatio option)
          in _PlayerAspectRatio.values.indexed)
        MenuItemButton(
          onPressed: () => _setAspectRatio(index),
          child: _menuLabel(option.label, selected: _aspectRatioIndex == index),
        ),
    ];
  }

  void _showVideoInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Colors.white12),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.only(top: 18, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          '视频详情',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  label: '片名',
                  value: widget.mediaItem.title,
                ),
                const Divider(height: 1, color: Colors.white12),
                _buildInfoRow(
                  context,
                  label: '当前剧集',
                  value: _currentEpisodeName,
                ),
                const Divider(height: 1, color: Colors.white12),
                _buildInfoRow(
                  context,
                  label: '播放地址',
                  value: _currentMediaUrl,
                  mono: true,
                  copyable: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool mono = false,
    bool copyable = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: copyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              _showPillToastMsg('已复制到剪贴板');
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value.isEmpty ? '（无）' : value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                  fontFamily: mono ? 'monospace' : null,
                  fontFamilyFallback: mono
                      ? const ['Consolas', 'Menlo', 'Roboto Mono']
                      : null,
                ),
              ),
            ),
            if (copyable)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.content_copy_rounded,
                  size: 16,
                  color: scheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- HUD ----------

  Widget _buildHudIconTile({
    required IconData icon,
    required Color container,
    required Color onContainer,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: onContainer, size: 22),
    );
  }

  Widget _buildSeekHud(ColorScheme scheme) {
    final visible = _showSeekHud && !_lockPanel;
    final forward = _previewPosition >= _position;
    final offset =
        (_previewPosition.inMilliseconds - _position.inMilliseconds).abs();
    final offsetText =
        '${forward ? '+' : '-'}${_formatDuration(Duration(milliseconds: offset))}';
    final progress = _duration.inMilliseconds > 0
        ? (_previewPosition.inMilliseconds / _duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return _HudPill(
      visible: visible,
      width: 248,
      background: scheme.surfaceContainerHighest,
      border: scheme.outlineVariant.withValues(alpha: 0.34),
      accentGlow: scheme.secondaryContainer.withValues(
        alpha: visible ? 0.24 : 0,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: ColoredBox(color: scheme.secondaryContainer),
              ),
            ),
          ),
          Row(
            children: [
              _buildHudIconTile(
                icon: forward
                    ? Icons.fast_forward_rounded
                    : Icons.fast_rewind_rounded,
                container: scheme.secondary,
                onContainer: scheme.onSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offsetText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${_formatDuration(_previewPosition)} / ${_formatDuration(_duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedHud(ColorScheme scheme) {
    final visible = _showSpeedHud && !_lockPanel;
    final container = scheme.inverseSurface;
    final onContainer = scheme.onInverseSurface;
    final surface = scheme.surfaceContainerHighest;
    final border = scheme.outlineVariant.withValues(alpha: 0.22);

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, -0.12),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: visible ? 1 : 0.96,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: 94,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: container,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.speed_rounded,
                        color: onContainer,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_displaySpeed.toStringAsFixed(1)}x',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdjustmentHud(ColorScheme scheme) {
    final isBrightness = _showBrightnessHud;
    final show = _showVolumeHud || _showBrightnessHud;
    final visible = show && !_lockPanel;
    final accent = isBrightness ? scheme.tertiary : scheme.primary;
    final container = isBrightness ? scheme.tertiary : scheme.primary;
    final onContainer = isBrightness ? scheme.onTertiary : scheme.onPrimary;
    final value = isBrightness ? _currentBrightness : _currentVolume;
    final percent = (value * 100).round();
    final icon = isBrightness
        ? (percent <= 8
            ? Icons.brightness_low_rounded
            : percent < 55
                ? Icons.brightness_medium_rounded
                : Icons.brightness_high_rounded)
        : (percent <= 0
            ? Icons.volume_off_rounded
            : percent < 45
                ? Icons.volume_down_rounded
                : Icons.volume_up_rounded);

    return _HudPill(
      visible: visible,
      width: 200,
      background: scheme.surfaceContainerHighest,
      border: scheme.outlineVariant.withValues(alpha: 0.34),
      accentGlow: accent.withValues(alpha: visible ? 0.24 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: container,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                icon,
                key: ValueKey(icon),
                color: onContainer,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildAdjustmentTrack(accent, value)),
        ],
      ),
    );
  }

  Widget _buildAdjustmentTrack(Color accent, double value) {
    return SizedBox(
      height: 20,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * value.clamp(0.0, 1.0);
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: accent.withValues(alpha: 0.18),
                  ),
                ),
              ),
              if (width > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(color: accent),
                  ),
                ),
              if (width > 0 && width < constraints.maxWidth)
                Positioned(
                  left: (width - 1.5).clamp(0.0, constraints.maxWidth - 1.5),
                  top: 1,
                  bottom: 1,
                  width: 3,
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHudLayer() {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      top: 25,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            _buildSeekHud(scheme),
            _buildSpeedHud(scheme),
            _buildAdjustmentHud(scheme),
          ],
        ),
      ),
    );
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
            _currentVolume = (_currentVolume - event.scrollDelta.dy / 20)
                .clamp(0.0, 1.0);
            _showVolumeHud = true;
            _showBrightnessHud = false;
          });
          _player.setVolume(_currentVolume * 100);
          _endAdjustment();
        },
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_lockPanel) return;
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
          _player.setRate(_longPressSpeed);
        },
        onLongPressEnd: (_) => _endLongPress(),
        onLongPressCancel: () => _endLongPress(),
        onHorizontalDragStart: (_) {
          if (_lockPanel) return;
          setState(() {
            _dragSeekStart = _position;
            _previewPosition = _position;
            _showSeekHud = true;
          });
        },
        onHorizontalDragUpdate: (details) {
          if (_lockPanel) return;
          final scale = 180000 / screenWidth;
          final target = _dragSeekStart +
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
            _showVolumeHud = !_adjustingBrightness;
            _showBrightnessHud = _adjustingBrightness;
          });
        },
        onVerticalDragUpdate: (details) {
          if (_lockPanel) return;
          final delta = details.delta.dy;
          if (_adjustingBrightness) {
            final level = screenHeight * 2;
            setState(() {
              _currentBrightness =
                  (_currentBrightness - delta / level).clamp(0.0, 1.0);
            });
          } else {
            final level = screenHeight * 0.03;
            final volume = (_preciseVolume - delta / level).clamp(0.0, 1.0);
            _currentVolume = volume;
            _player.setVolume(volume * 100);
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

  // ---------- 顶栏 ----------

  Widget _buildTopControls(bool compact) {
    final visible = _showControls && !_lockPanel;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, -0.6),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
              height: 50,
              padding: const EdgeInsets.only(bottom: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black45, Colors.transparent],
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                left: !compact,
                right: !compact,
                child: Row(
                  children: [
                    IconButton(
                      color: Colors.white,
                      tooltip: '返回',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: compact
                          ? const SizedBox(height: 40)
                          : Text(
                              ' ${widget.mediaItem.title} [$_currentEpisodeName]',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .fontSize,
                              ),
                            ),
                    ),
                    _anchorButton(
                      tooltip: '更多选项',
                      child: const Icon(Icons.more_vert, color: Colors.white),
                      menuChildren: [
                        if (compact) ...[
                          SubmenuButton(
                            menuChildren: _aspectRatioMenuItems(),
                            child: _menuLabel('视频比例'),
                          ),
                          SubmenuButton(
                            menuChildren: _speedMenuItems(),
                            child: _menuLabel('倍速'),
                          ),
                        ],
                        MenuItemButton(
                          onPressed: _showVideoInfoDialog,
                          child: _menuLabel('视频详情'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 底栏 ----------

  ProgressBar _buildProgressBar(TimeLabelLocation location) {
    return ProgressBar(
      thumbRadius: 8,
      thumbGlowRadius: 18,
      timeLabelLocation: location,
      timeLabelTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      progress: _position,
      buffered: _buffered,
      total: _duration,
      onSeek: (duration) {
        _player.seek(duration);
        _releasePanelHold();
      },
      onDragStart: (_) {
        _acquirePanelHold();
      },
      onDragUpdate: (_) {},
      onDragEnd: _releasePanelHold,
    );
  }

  Widget _buildWideControls() {
    final speedText = _playbackSpeed == 1 ? '倍速' : '${_playbackSpeed}x';
    return Row(
      children: [
        const Spacer(),
        _anchorButton(
          tooltip: '倍速',
          child: Text(
            speedText,
            style: const TextStyle(color: Colors.white),
          ),
          menuChildren: _speedMenuItems(),
        ),
        _anchorButton(
          tooltip: '视频比例',
          child: const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
          menuChildren: _aspectRatioMenuItems(),
        ),
        IconButton(
          color: Colors.white,
          icon: const Icon(Icons.menu_open_rounded),
          tooltip: '选集面板',
          onPressed: _toggleSidebar,
        ),
      ],
    );
  }

  Widget _buildFullscreenButton() {
    return IconButton(
      color: Colors.white,
      tooltip: '退出全屏',
      icon: const Icon(Icons.fullscreen_exit_rounded),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildBottomControls(bool compact) {
    final placement = _TimeLabelPlacement.forViewport(
      MediaQuery.sizeOf(context),
    );
    final timeLabel = Text(
      '${compact ? '    ' : ''}${_formatDuration(_position)} / ${_formatDuration(_duration)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
    final playPause = IconButton(
      tooltip: _isPlaying ? '暂停' : '播放',
      onPressed: _togglePlayPause,
      icon: _PlayPauseIcon(playing: _isPlaying),
    );
    final nextEpisode = IconButton(
      color: Colors.white,
      tooltip: '下一集',
      icon: const Icon(Icons.skip_next_rounded),
      onPressed: _onNextEpisodePress,
    );
    final fullscreenButton = _buildFullscreenButton();

    final visible = _showControls && !_lockPanel;

    final Widget transport;
    if (compact) {
      transport = Row(
        children: [
          playPause,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildProgressBar(TimeLabelLocation.none),
            ),
          ),
          timeLabel,
          fullscreenButton,
        ],
      );
    } else {
      transport = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (placement == _TimeLabelPlacement.aboveProgress)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: timeLabel,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildProgressBar(
              placement == _TimeLabelPlacement.besideProgress
                  ? TimeLabelLocation.sides
                  : TimeLabelLocation.none,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                playPause,
                nextEpisode,
                if (placement == _TimeLabelPlacement.afterPlaybackButtons)
                  const Padding(padding: EdgeInsets.only(left: 10)),
                Expanded(child: _buildWideControls()),
                fullscreenButton,
              ],
            ),
          ),
          if (placement != _TimeLabelPlacement.aboveProgress)
            const SizedBox(height: 6),
        ],
      );
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 0.6),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black45, Colors.transparent],
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: !compact,
                left: !compact,
                right: !compact,
                child: transport,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 右侧锁定 ----------

  Widget _buildRightControls(bool compact) {
    final visible = _lockPanel || (!compact && _showControls);
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                children: [
                  const Spacer(),
                  IconButton(
                    color: Colors.white,
                    tooltip: _lockPanel ? '解锁面板' : '锁定面板',
                    icon: Icon(
                      _lockPanel ? Icons.lock_outline : Icons.lock_open,
                    ),
                    onPressed: _toggleLock,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- 右侧 300px 选集面板 ----------

  Widget _buildSidebarPanel() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        width: _sidebarOpen ? 300 : 0,
        color: const Color(0xFF121212),
        child: ClipRect(
          child: DefaultTabController(
            length: 1,
            child: Column(
              children: [
                Material(
                  color: const Color(0xFF1F1F1F),
                  child: TabBar(
                    tabAlignment: TabAlignment.center,
                    isScrollable: true,
                    tabs: [Tab(text: '选集 (${widget.episodes.length})')],
                  ),
                ),
                Expanded(
                  child: widget.episodes.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无选集',
                            style: TextStyle(color: Colors.white38),
                          ),
                        )
                      : Scrollbar(
                          controller: _episodeScrollController,
                          child: ListView.builder(
                            controller: _episodeScrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: widget.episodes.length,
                            itemBuilder: (context, index) {
                              final ep = widget.episodes[index];
                              final isCurrent =
                                  index == _currentEpisodeIndex;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _sidebarOpen = false;
                                  });
                                  _changeEpisode(index);
                                },
                                child: SizedBox(
                                  height: 64,
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    color: isCurrent
                                        ? primaryColor
                                        : const Color(0xFF121212),
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        ep.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  // ---------- 中间状态 ----------

  Widget _buildCenter() {
    return Positioned.fill(
      child: Center(
        child: _hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '播放出错',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('错误信息'),
                              content: SelectableText(_errorMessage),
                              actions: [
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('关闭'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('错误信息'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                          });
                          _playEpisode(_currentEpisodeIndex);
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ],
              )
            : _isBuffering
            ? const CircularProgressIndicator(color: Colors.white)
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width <
        MediaQuery.textScalerOf(context).scale(600);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Theme(
        data: ThemeData.dark(useMaterial3: true),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. media_kit 解码渲染视图
              Video(
                controller: _videoController,
                controls: NoVideoControls,
                fit: _PlayerAspectRatio.values[_aspectRatioIndex].fit,
              ),

              // 2. 视觉亮度遮罩（左半边上下滑动）
              if (_currentBrightness < 0.995)
                IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: (1 - _currentBrightness) * 0.85,
                    ),
                  ),
                ),

              // 3. 顶部居中 HUD
              _buildHudLayer(),

              // 4. 手势层
              _buildGestureLayer(),

              // 5. 中间状态
              _buildCenter(),

              // 6. 左下角消息胶囊
              if (_showPillToast)
                Positioned(
                  left: 0,
                  bottom: 100,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        _pillToastText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),

              // 7. 底栏
              _buildBottomControls(compact),

              // 8. 顶栏
              _buildTopControls(compact),

              // 9. 右侧锁定
              _buildRightControls(compact),

              // 10. 选集面板遮罩
              if (_sidebarOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _sidebarOpen = false;
                      });
                    },
                    child: Container(color: Colors.black54),
                  ),
                ),

              // 11. 选集面板
              _buildSidebarPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.visible,
    required this.width,
    required this.background,
    required this.border,
    required this.accentGlow,
    required this.child,
  });

  final bool visible;
  final double width;
  final Color background;
  final Color border;
  final Color accentGlow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -0.18),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          scale: visible ? 1 : 0.92,
          duration: duration,
          curve: Curves.easeOutBack,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: accentGlow,
                    blurRadius: 32,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseIcon extends StatefulWidget {
  final bool playing;

  const _PlayPauseIcon({required this.playing});

  @override
  State<_PlayPauseIcon> createState() => _PlayPauseIconState();
}

class _PlayPauseIconState extends State<_PlayPauseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.playing ? 1.0 : 0.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PlayPauseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) {
      if (widget.playing) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedIcon(
      color: Colors.white,
      size: 24,
      icon: AnimatedIcons.play_pause,
      progress: _controller,
    );
  }
}