import 'package:flutter/material.dart';

import 'player_common.dart';

enum PlayerAdjustmentHudType { brightness, volume }

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
    return IgnorePointer(
      child: AnimatedOpacity(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      ),
    );
  }
}

/// 拖动进度时的偏移 HUD（进度底色 + 快进/回退图标 + 时间）
class SeekHud extends StatefulWidget {
  const SeekHud({
    super.key,
    required this.visible,
    required this.position,
    required this.previewPosition,
    required this.duration,
    this.disableAnimations = false,
  });

  final bool visible;
  final Duration position;
  final Duration previewPosition;
  final Duration duration;
  final bool disableAnimations;

  @override
  State<SeekHud> createState() => _SeekHudState();
}

class _SeekHudState extends State<SeekHud> {
  late Duration _displayPosition;
  late Duration _displayPreviewPosition;
  late Duration _displayDuration;
  bool _snapProgressOnNextBuild = false;

  @override
  void initState() {
    super.initState();
    _displayPosition = widget.position;
    _displayPreviewPosition = widget.previewPosition;
    _displayDuration = widget.duration;
  }

  @override
  void didUpdateWidget(covariant SeekHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _displayPosition = widget.position;
      _displayPreviewPosition = widget.previewPosition;
      _displayDuration = widget.duration;
      if (!oldWidget.visible) {
        _snapProgressOnNextBuild = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final forward = _displayPreviewPosition >= _displayPosition;
    final offset =
        (_displayPreviewPosition.inMilliseconds -
                _displayPosition.inMilliseconds)
            .abs();
    final offsetText =
        '${forward ? '+' : '-'}${formatPlayerDuration(Duration(milliseconds: offset))}';
    final progress = _displayDuration.inMilliseconds > 0
        ? (_displayPreviewPosition.inMilliseconds /
                  _displayDuration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;
    final snapProgress = _snapProgressOnNextBuild;
    if (snapProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _snapProgressOnNextBuild = false;
        });
      });
    }

    return HudPill(
      visible: widget.visible,
      width: 248,
      background: scheme.surfaceContainerHighest,
      border: scheme.outlineVariant.withValues(alpha: 0.34),
      accentGlow: scheme.primary.withValues(
        alpha: widget.visible ? 0.28 : 0,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: widget.disableAnimations || snapProgress
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: animatedProgress,
                    child: ColoredBox(color: scheme.primary.withValues(alpha: 0.28)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              children: [
                _HudIconTile(
                  icon: forward
                      ? Icons.fast_forward_rounded
                      : Icons.fast_rewind_rounded,
                  container: scheme.primary,
                  onContainer: scheme.onPrimary,
                  size: 36,
                  iconSize: 22,
                  radius: 20,
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
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${formatPlayerDuration(_displayPreviewPosition)} / ${formatPlayerDuration(_displayDuration)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 长按倍速 HUD
class SpeedHud extends StatefulWidget {
  const SpeedHud({
    super.key,
    required this.visible,
    required this.displaySpeed,
    this.disableAnimations = false,
  });

  final bool visible;
  final double displaySpeed;
  final bool disableAnimations;

  @override
  State<SpeedHud> createState() => _SpeedHudState();
}

class _SpeedHudState extends State<SpeedHud> {
  late double _displaySpeed;

  @override
  void initState() {
    super.initState();
    _displaySpeed = widget.displaySpeed;
  }

  @override
  void didUpdateWidget(covariant SpeedHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _displaySpeed = widget.displaySpeed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const duration = Duration(milliseconds: 160);

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: widget.visible ? Offset.zero : const Offset(0, -0.12),
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedScale(
            scale: widget.visible ? 1 : 0.96,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: 94,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(
                        alpha: widget.visible ? 0.28 : 0,
                      ),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
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
                    _HudIconTile(
                      icon: Icons.speed_rounded,
                      container: scheme.primary,
                      onContainer: scheme.onPrimary,
                      size: 22,
                      iconSize: 15,
                      radius: 12,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_displaySpeed.toStringAsFixed(1)}x',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: scheme.primary,
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
///
/// 有状态组件：仅在 [visible] 为 true 时锁存类型与数值，淡出过程中保持
/// 最后一次显示的内容，避免结束后瞬间切换到另一侧。
class AdjustmentHud extends StatefulWidget {
  const AdjustmentHud({
    super.key,
    required this.visible,
    required this.type,
    required this.value,
    this.disableAnimations = false,
  });

  final bool visible;
  final PlayerAdjustmentHudType type;

  /// 亮度与音量均为 0.0 ~ 1.0。
  final double value;
  final bool disableAnimations;

  @override
  State<AdjustmentHud> createState() => _AdjustmentHudState();
}

class _AdjustmentHudState extends State<AdjustmentHud> {
  late PlayerAdjustmentHudType _displayType;
  late double _displayValue;
  bool _snapProgressOnNextBuild = false;

  @override
  void initState() {
    super.initState();
    _displayType = widget.type;
    _displayValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant AdjustmentHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _displayType = widget.type;
      _displayValue = widget.value;
      if (!oldWidget.visible) {
        _snapProgressOnNextBuild = true;
      }
    }
  }

  double get _progress => _displayValue.clamp(0.0, 1.0);

  int get _percent => (_progress * 100).round();

  IconData get _icon {
    if (_displayType == PlayerAdjustmentHudType.brightness) {
      if (_percent <= 8) {
        return Icons.brightness_low_rounded;
      }
      if (_percent < 55) {
        return Icons.brightness_medium_rounded;
      }
      return Icons.brightness_high_rounded;
    }
    if (_percent <= 0) {
      return Icons.volume_off_rounded;
    }
    if (_percent < 45) {
      return Icons.volume_down_rounded;
    }
    return Icons.volume_up_rounded;
  }

  Color _accent(ColorScheme scheme) {
    return switch (_displayType) {
      PlayerAdjustmentHudType.brightness => scheme.tertiary,
      PlayerAdjustmentHudType.volume => scheme.primary,
    };
  }

  Color _container(ColorScheme scheme) {
    return switch (_displayType) {
      PlayerAdjustmentHudType.brightness => scheme.tertiary,
      PlayerAdjustmentHudType.volume => scheme.primary,
    };
  }

  Color _onContainer(ColorScheme scheme) {
    return switch (_displayType) {
      PlayerAdjustmentHudType.brightness => scheme.onTertiary,
      PlayerAdjustmentHudType.volume => scheme.onPrimary,
    };
  }

  Color _activeTracker(ColorScheme scheme) {
    return switch (_displayType) {
      PlayerAdjustmentHudType.brightness => scheme.tertiary,
      PlayerAdjustmentHudType.volume => scheme.primary,
    };
  }

  Color _inactiveTracker(ColorScheme scheme) {
    return switch (_displayType) {
      PlayerAdjustmentHudType.brightness => scheme.tertiary.withValues(alpha: 0.22),
      PlayerAdjustmentHudType.volume => scheme.primary.withValues(alpha: 0.22),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accent(scheme);
    final container = _container(scheme);
    final onContainer = _onContainer(scheme);
    final snapProgress = _snapProgressOnNextBuild;
    if (snapProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _snapProgressOnNextBuild = false;
        });
      });
    }

    return HudPill(
      visible: widget.visible,
      width: 200,
      background: scheme.surfaceContainerHighest,
      border: scheme.outlineVariant.withValues(alpha: 0.34),
      accentGlow: accent.withValues(alpha: widget.visible ? 0.24 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: widget.disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: container,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedSwitcher(
              duration: widget.disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                _icon,
                key: ValueKey(_icon),
                color: onContainer,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 32,
                activeTrackColor: _activeTracker(scheme),
                inactiveTrackColor: _inactiveTracker(scheme),
                thumbColor: _activeTracker(scheme),
                overlayShape: SliderComponentShape.noOverlay,
                trackShape: const _HudSliderTrackShape(
                  outerRadius: 12,
                  innerRadius: 2,
                  thumbGap: 12,
                  edgeInset: 6,
                ),
                thumbShape: const _HudSliderThumbShape(
                  width: 4,
                  height: 40,
                  cornerRadius: 2,
                ),
                tickMarkShape: SliderTickMarkShape.noTickMark,
                padding: EdgeInsets.zero,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _progress),
                duration: widget.disableAnimations || snapProgress
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, child) {
                  return Slider(value: animatedProgress, onChanged: (_) {});
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// HUD 内的圆形图标瓦片
class _HudIconTile extends StatelessWidget {
  const _HudIconTile({
    required this.icon,
    required this.container,
    required this.onContainer,
    this.size = 36,
    this.iconSize = 22,
    this.radius = 20,
  });

  final IconData icon;
  final Color container;
  final Color onContainer;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(radius),
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
          size: iconSize,
        ),
      ),
    );
  }
}

class _HudSliderTrackShape extends SliderTrackShape {
  const _HudSliderTrackShape({
    required this.outerRadius,
    required this.innerRadius,
    this.thumbGap = 10,
    this.edgeInset = 6,
  });

  final double outerRadius;
  final double innerRadius;
  final double thumbGap;
  final double edgeInset;

  Rect _baseTrackRect({
    required RenderBox parentBox,
    required Offset offset,
    required SliderThemeData sliderTheme,
    required bool isEnabled,
    required bool isDiscrete,
  }) {
    final thumbWidth =
        sliderTheme.thumbShape?.getPreferredSize(isEnabled, isDiscrete).width ??
        0;
    final trackHeight = sliderTheme.trackHeight ?? 0;
    final trackLeft = offset.dx + thumbWidth / 2;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - thumbWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final baseTrackRect = _baseTrackRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final safeInset = edgeInset.clamp(0.0, baseTrackRect.width / 2).toDouble();
    return Rect.fromLTRB(
      baseTrackRect.left + safeInset,
      baseTrackRect.top,
      baseTrackRect.right - safeInset,
      baseTrackRect.bottom,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final canvas = context.canvas;
    final baseTrackRect = _baseTrackRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final effectiveTrackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final activeColor =
        ColorTween(
          begin: sliderTheme.disabledActiveTrackColor,
          end: sliderTheme.activeTrackColor,
        ).evaluate(enableAnimation) ??
        Colors.transparent;
    final inactiveColor =
        ColorTween(
          begin: sliderTheme.disabledInactiveTrackColor,
          end: sliderTheme.inactiveTrackColor,
        ).evaluate(enableAnimation) ??
        Colors.transparent;

    final thumbX = thumbCenter.dx.clamp(
      effectiveTrackRect.left,
      effectiveTrackRect.right,
    );
    var halfGap = thumbGap / 2;
    final leftRoom = thumbX - baseTrackRect.left;
    final rightRoom = baseTrackRect.right - thumbX;
    if (halfGap > leftRoom) {
      halfGap = leftRoom;
    }
    if (halfGap > rightRoom) {
      halfGap = rightRoom;
    }

    final leftEnd = (thumbX - halfGap).clamp(
      baseTrackRect.left,
      baseTrackRect.right,
    );
    final rightStart = (thumbX + halfGap).clamp(
      baseTrackRect.left,
      baseTrackRect.right,
    );

    final leftRect = Rect.fromLTRB(
      baseTrackRect.left,
      baseTrackRect.top,
      leftEnd,
      baseTrackRect.bottom,
    );
    final rightRect = Rect.fromLTRB(
      rightStart,
      baseTrackRect.top,
      baseTrackRect.right,
      baseTrackRect.bottom,
    );

    final leftColor = textDirection == TextDirection.ltr
        ? activeColor
        : inactiveColor;
    final rightColor = textDirection == TextDirection.ltr
        ? inactiveColor
        : activeColor;
    final hasLeftSegment = leftRect.width > 0;
    final hasRightSegment = rightRect.width > 0;

    if (hasLeftSegment) {
      _paintSegment(
        canvas: canvas,
        segmentRect: leftRect,
        color: leftColor,
        startRadius: outerRadius,
        endRadius: innerRadius,
        anchorToStart: true,
      );
    }

    if (hasRightSegment) {
      _paintSegment(
        canvas: canvas,
        segmentRect: rightRect,
        color: rightColor,
        startRadius: innerRadius,
        endRadius: outerRadius,
        anchorToStart: false,
      );
    }
  }

  void _paintSegment({
    required Canvas canvas,
    required Rect segmentRect,
    required Color color,
    required double startRadius,
    required double endRadius,
    required bool anchorToStart,
  }) {
    if (segmentRect.width <= 0) {
      return;
    }

    final minTemplateWidth = startRadius + endRadius;
    final templateWidth = segmentRect.width < minTemplateWidth
        ? minTemplateWidth
        : segmentRect.width;
    final templateRect = anchorToStart
        ? Rect.fromLTWH(
            segmentRect.left,
            segmentRect.top,
            templateWidth,
            segmentRect.height,
          )
        : Rect.fromLTWH(
            segmentRect.right - templateWidth,
            segmentRect.top,
            templateWidth,
            segmentRect.height,
          );

    canvas.save();
    canvas.clipRect(segmentRect);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        templateRect,
        topLeft: Radius.circular(startRadius),
        bottomLeft: Radius.circular(startRadius),
        topRight: Radius.circular(endRadius),
        bottomRight: Radius.circular(endRadius),
      ),
      Paint()..color = color,
    );
    canvas.restore();
  }
}

class _HudSliderThumbShape extends SliderComponentShape {
  const _HudSliderThumbShape({
    required this.width,
    required this.height,
    required this.cornerRadius,
  });

  final double width;
  final double height;
  final double cornerRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final thumbColor =
        ColorTween(
          begin: sliderTheme.disabledThumbColor,
          end: sliderTheme.thumbColor,
        ).evaluate(enableAnimation) ??
        Colors.transparent;
    final canvas = context.canvas;

    final thumbRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(thumbRect, Radius.circular(cornerRadius)),
      Paint()..color = thumbColor,
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
    required this.adjustmentType,
    required this.value,
    this.adjustmentDisableAnimations = false,
  });

  final bool seekVisible;
  final bool speedVisible;
  final bool adjustmentVisible;
  final Duration position;
  final Duration previewPosition;
  final Duration duration;
  final double displaySpeed;
  final PlayerAdjustmentHudType adjustmentType;
  final double value;

  /// 手势调节过程中关闭补间动画，让数值 1:1 跟随手指。
  final bool adjustmentDisableAnimations;

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
              type: adjustmentType,
              value: value,
              disableAnimations: adjustmentDisableAnimations,
            ),
          ],
        ),
      ),
    );
  }
}
