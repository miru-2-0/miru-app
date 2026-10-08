import 'package:flutter/material.dart';

import 'player_common.dart';

/// 顶部居中 HUD 的胶囊外壳（快进回退 / 音量亮度共用）
class HudPill extends StatelessWidget {
  const HudPill({
    super.key,
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
                  BoxShadow(color: accentGlow, blurRadius: 32, spreadRadius: 1),
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

/// HUD 内的圆形图标瓦片
class HudIconTile extends StatelessWidget {
  const HudIconTile({
    super.key,
    required this.icon,
    required this.container,
    required this.onContainer,
  });

  final IconData icon;
  final Color container;
  final Color onContainer;

  @override
  Widget build(BuildContext context) {
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
}

/// 拖动进度时的偏移 HUD（进度底色 + 快进/回退图标 + 时间）
class SeekHud extends StatelessWidget {
  const SeekHud({
    super.key,
    required this.visible,
    required this.position,
    required this.previewPosition,
    required this.duration,
  });

  final bool visible;
  final Duration position;
  final Duration previewPosition;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final forward = previewPosition >= position;
    final offset = (previewPosition.inMilliseconds - position.inMilliseconds)
        .abs();
    final offsetText =
        '${forward ? '+' : '-'}${formatPlayerDuration(Duration(milliseconds: offset))}';
    final progress = duration.inMilliseconds > 0
        ? (previewPosition.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          )
        : 0.0;

    return HudPill(
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
              HudIconTile(
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
                      '${formatPlayerDuration(previewPosition)} / ${formatPlayerDuration(duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
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
}

/// 长按倍速 HUD
class SpeedHud extends StatelessWidget {
  const SpeedHud({
    super.key,
    required this.visible,
    required this.displaySpeed,
  });

  final bool visible;
  final double displaySpeed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                        '${displaySpeed.toStringAsFixed(1)}x',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
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
}

/// 音量 / 亮度调节 HUD（滑条）
class AdjustmentHud extends StatelessWidget {
  const AdjustmentHud({
    super.key,
    required this.visible,
    required this.isBrightness,
    required this.value,
  });

  final bool visible;
  final bool isBrightness;
  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isBrightness ? scheme.tertiary : scheme.primary;
    final container = isBrightness ? scheme.tertiary : scheme.primary;
    final onContainer = isBrightness ? scheme.onTertiary : scheme.onPrimary;
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

    return HudPill(
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
          Expanded(child: _AdjustmentTrack(accent, value)),
        ],
      ),
    );
  }
}

/// 调节滑条本体（底槽 + 填充 + 指针）
class _AdjustmentTrack extends StatelessWidget {
  const _AdjustmentTrack(this.accent, this.value);

  final Color accent;
  final double value;

  @override
  Widget build(BuildContext context) {
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
                  child: ColoredBox(color: accent.withValues(alpha: 0.18)),
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
}

/// 顶部居中 HUD 层（快进回退 / 倍速 / 音量亮度叠放）
class PlayerHudLayer extends StatelessWidget {
  const PlayerHudLayer({
    super.key,
    required this.seekVisible,
    required this.speedVisible,
    required this.adjustmentVisible,
    required this.position,
    required this.previewPosition,
    required this.duration,
    required this.displaySpeed,
    required this.isBrightness,
    required this.value,
  });

  final bool seekVisible;
  final bool speedVisible;
  final bool adjustmentVisible;
  final Duration position;
  final Duration previewPosition;
  final Duration duration;
  final double displaySpeed;
  final bool isBrightness;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 25,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SeekHud(
              visible: seekVisible,
              position: position,
              previewPosition: previewPosition,
              duration: duration,
            ),
            SpeedHud(visible: speedVisible, displaySpeed: displaySpeed),
            AdjustmentHud(
              visible: adjustmentVisible,
              isBrightness: isBrightness,
              value: value,
            ),
          ],
        ),
      ),
    );
  }
}
