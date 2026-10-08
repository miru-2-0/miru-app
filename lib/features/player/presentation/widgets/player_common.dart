import 'package:flutter/material.dart';

/// 播放倍速档位（对齐 Kazumi v2.3.6）
const List<double> kPlayerSpeeds = <double>[
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

/// 长按画面时的临时倍速
const double kPlayerLongPressSpeed = 2.0;

/// 视频画面填充模式
enum PlayerAspectRatio {
  automatic('自动', BoxFit.contain),
  crop('裁剪', BoxFit.cover),
  stretch('拉伸', BoxFit.fill),
  ratio4x3('4:3', BoxFit.fill);

  const PlayerAspectRatio(this.label, this.fit);

  final String label;
  final BoxFit fit;
}

/// 底栏时间标签的摆放位置（按视口宽高比推断）
enum TimeLabelPlacement {
  aboveProgress,
  besideProgress,
  afterPlaybackButtons;

  static TimeLabelPlacement forViewport(Size viewport) {
    final hasRoomForSideLabels =
        viewport.shortestSide >= 600 &&
        viewport.shortestSide / viewport.longestSide >= 9 / 16;
    return hasRoomForSideLabels ? besideProgress : aboveProgress;
  }
}

/// 时长格式化：`MM:SS`，超过一小时为 `HH:MM:SS`
String formatPlayerDuration(Duration d) {
  String pad(int n) => n.toString().padLeft(2, '0');
  final hours = pad(d.inHours % 24);
  final minutes = pad(d.inMinutes % 60);
  final seconds = pad(d.inSeconds % 60);
  if (hours == '00') return '$minutes:$seconds';
  return '$hours:$minutes:$seconds';
}

/// 播放器菜单的统一深色样式
const MenuStyle kPlayerMenuStyle = MenuStyle(
  backgroundColor: WidgetStatePropertyAll(Color(0xFF242424)),
  surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
  elevation: WidgetStatePropertyAll(6),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
);

/// 菜单文字项（选中项追加对勾）
Widget playerMenuLabel(String label, {bool selected = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        if (selected)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.check_rounded, size: 18, color: Colors.white),
          ),
      ],
    ),
  );
}

/// 带 Tooltip 的菜单锚点按钮（IconButton + MenuAnchor 开合）
class PlayerMenuAnchor extends StatelessWidget {
  const PlayerMenuAnchor({
    super.key,
    required this.child,
    required this.menuChildren,
    this.tooltip,
    this.onOpen,
    this.onClose,
  });

  final Widget child;
  final List<Widget> menuChildren;
  final String? tooltip;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: kPlayerMenuStyle,
      menuChildren: menuChildren,
      onOpen: onOpen,
      onClose: onClose,
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
}

/// 顶栏 / 底栏共用的菜单状态与回调
class PlayerMenuActions {
  const PlayerMenuActions({
    required this.currentSpeed,
    required this.aspectRatioIndex,
    required this.onSpeedChanged,
    required this.onAspectRatioChanged,
    required this.onShowVideoInfo,
    required this.onMenuOpen,
    required this.onMenuClose,
  });

  final double currentSpeed;
  final int aspectRatioIndex;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<int> onAspectRatioChanged;
  final VoidCallback onShowVideoInfo;
  final VoidCallback onMenuOpen;
  final VoidCallback onMenuClose;

  /// 倍速子菜单项
  List<Widget> speedMenuItems() {
    return [
      for (final speed in kPlayerSpeeds)
        MenuItemButton(
          onPressed: () => onSpeedChanged(speed),
          child: playerMenuLabel('${speed}x', selected: currentSpeed == speed),
        ),
    ];
  }

  /// 视频比例子菜单项
  List<Widget> aspectRatioMenuItems() {
    return [
      for (final (int index, PlayerAspectRatio option)
          in PlayerAspectRatio.values.indexed)
        MenuItemButton(
          onPressed: () => onAspectRatioChanged(index),
          child: playerMenuLabel(
            option.label,
            selected: aspectRatioIndex == index,
          ),
        ),
    ];
  }
}
