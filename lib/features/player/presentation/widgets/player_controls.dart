import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:miru/app/l10n/l10n_extension.dart';

import 'player_common.dart';
import 'player_dialogs.dart';

/// 控制栏淡入淡出外壳：不可见时透传点击并做透明度 / 位移过渡
class PlayerFadeLayer extends StatelessWidget {
  const PlayerFadeLayer({
    super.key,
    required this.visible,
    required this.child,
    this.slideOffset,
  });

  final bool visible;
  final Widget child;

  /// 提供时附加纵向滑入滑出动画（如顶栏上滑、底栏下滑）
  final Offset? slideOffset;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 200);
    final Widget body = slideOffset == null
        ? child
        : AnimatedSlide(
            offset: visible ? Offset.zero : slideOffset!,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: child,
          );
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: body,
      ),
    );
  }
}

/// 顶栏：返回 + 单行标题 + 更多菜单
class PlayerTopControls extends StatelessWidget {
  const PlayerTopControls({
    super.key,
    required this.visible,
    required this.compact,
    required this.title,
    required this.episodeName,
    required this.menus,
    required this.onBack,
  });

  final bool visible;
  final bool compact;
  final String title;
  final String episodeName;
  final PlayerMenuActions menus;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: PlayerFadeLayer(
        visible: visible,
        slideOffset: const Offset(0, -0.6),
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
                  tooltip: l10n.back,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                ),
                Expanded(
                  child: compact
                      ? const SizedBox(height: 40)
                      : Text(
                          ' $title [$episodeName]',
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
                PlayerMenuAnchor(
                  tooltip: l10n.moreOptions,
                  onOpen: menus.onMenuOpen,
                  onClose: menus.onMenuClose,
                  menuChildren: [
                    if (compact) ...[
                      SubmenuButton(
                        menuChildren: menus.aspectRatioMenuItems(),
                        child: playerMenuLabel(l10n.aspectRatio),
                      ),
                      SubmenuButton(
                        menuChildren: menus.speedMenuItems(),
                        child: playerMenuLabel(l10n.speed),
                      ),
                    ],
                    MenuItemButton(
                      onPressed: menus.onShowVideoInfo,
                      child: playerMenuLabel(l10n.videoDetail),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 底栏 transport bar：进度条 + 播放/下一集 + 倍速/比例/选集 + 退出全屏
class PlayerBottomControls extends StatelessWidget {
  const PlayerBottomControls({
    super.key,
    required this.visible,
    required this.compact,
    required this.position,
    required this.duration,
    required this.buffered,
    required this.isPlaying,
    required this.menus,
    required this.onTogglePlayPause,
    required this.onNextEpisode,
    required this.onToggleSidebar,
    required this.onSeek,
    required this.onPanelAcquire,
    required this.onPanelRelease,
  });

  final bool visible;
  final bool compact;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final bool isPlaying;
  final PlayerMenuActions menus;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onNextEpisode;
  final VoidCallback onToggleSidebar;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onPanelAcquire;
  final VoidCallback onPanelRelease;

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
      progress: position,
      buffered: buffered,
      total: duration,
      onSeek: (value) {
        onSeek(value);
        onPanelRelease();
      },
      onDragStart: (_) {
        onPanelAcquire();
      },
      onDragUpdate: (_) {},
      onDragEnd: onPanelRelease,
    );
  }

  Widget _buildWideControls(BuildContext context) {
    final l10n = context.l10n;
    final speedText = menus.currentSpeed == 1 ? l10n.speed : '${menus.currentSpeed}x';
    return Row(
      children: [
        const Spacer(),
        PlayerMenuAnchor(
          tooltip: l10n.speed,
          menuChildren: menus.speedMenuItems(),
          onOpen: menus.onMenuOpen,
          onClose: menus.onMenuClose,
          child: Text(speedText, style: const TextStyle(color: Colors.white)),
        ),
        PlayerMenuAnchor(
          tooltip: l10n.aspectRatio,
          menuChildren: menus.aspectRatioMenuItems(),
          onOpen: menus.onMenuOpen,
          onClose: menus.onMenuClose,
          child: const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
        ),
        IconButton(
          color: Colors.white,
          icon: const Icon(Icons.menu_open_rounded),
          tooltip: l10n.episodesPanel,
          onPressed: onToggleSidebar,
        ),
      ],
    );
  }

  Widget _buildFullscreenButton(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      color: Colors.white,
      tooltip: l10n.exitFullscreen,
      icon: const Icon(Icons.fullscreen_exit_rounded),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final placement = TimeLabelPlacement.forViewport(
      MediaQuery.sizeOf(context),
    );
    final timeLabel = Text(
      '${compact ? '    ' : ''}${formatPlayerDuration(position)} / ${formatPlayerDuration(duration)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
    final playPause = IconButton(
      tooltip: isPlaying ? l10n.pause : l10n.play,
      onPressed: onTogglePlayPause,
      icon: _PlayPauseIcon(playing: isPlaying),
    );
    final nextEpisode = IconButton(
      color: Colors.white,
      tooltip: l10n.nextEpisode,
      icon: const Icon(Icons.skip_next_rounded),
      onPressed: onNextEpisode,
    );
    final fullscreenButton = _buildFullscreenButton(context);

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
          if (placement == TimeLabelPlacement.aboveProgress)
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 10),
              child: timeLabel,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildProgressBar(
              placement == TimeLabelPlacement.besideProgress
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
                if (placement == TimeLabelPlacement.afterPlaybackButtons)
                  const Padding(padding: EdgeInsets.only(left: 10)),
                Expanded(child: _buildWideControls(context)),
                fullscreenButton,
              ],
            ),
          ),
          if (placement != TimeLabelPlacement.aboveProgress)
            const SizedBox(height: 6),
        ],
      );
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: PlayerFadeLayer(
        visible: visible,
        slideOffset: const Offset(0, 0.6),
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
    );
  }
}

/// 右侧居中的锁定按钮（锁定时常显）
class PlayerRightControls extends StatelessWidget {
  const PlayerRightControls({
    super.key,
    required this.visible,
    required this.locked,
    required this.onToggleLock,
  });

  final bool visible;
  final bool locked;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: PlayerFadeLayer(
        visible: visible,
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
                  tooltip: locked ? l10n.unlockPanel : l10n.lockPanel,
                  icon: Icon(locked ? Icons.lock_outline : Icons.lock_open),
                  onPressed: onToggleLock,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 中间状态：缓冲指示器 / 播放出错重试
class PlayerCenterOverlay extends StatelessWidget {
  const PlayerCenterOverlay({
    super.key,
    required this.hasError,
    required this.errorMessage,
    required this.buffering,
    required this.onRetry,
  });

  final bool hasError;
  final String errorMessage;
  final bool buffering;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Positioned.fill(
      child: Center(
        child: hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.playbackError,
                    style: const TextStyle(
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
                          showVideoErrorDialog(context, errorMessage);
                        },
                        child: Text(l10n.errorMessageTitle),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
                    ],
                  ),
                ],
              )
            : buffering
            ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// 左下角临时消息胶囊
class PlayerPillToast extends StatelessWidget {
  const PlayerPillToast({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

/// 播放 / 暂停切换图标（AnimatedIcons.play_pause）
class _PlayPauseIcon extends StatefulWidget {
  const _PlayPauseIcon({required this.playing});

  final bool playing;

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
