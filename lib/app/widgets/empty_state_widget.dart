import 'package:flutter/material.dart';

/// 全局统一的空状态显示组件，保持全应用一致的视觉风格与对齐基线
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onActionPressed,
    this.compact = false,
  });

  /// 状态图标（如 Icons.inbox_outlined / Icons.extension_outlined / Icons.favorite_border 等）
  final IconData icon;

  /// 主标题
  final String title;

  /// 补充说明或操作引导文字
  final String? subtitle;

  /// 操作按钮标签（可选）
  final String? actionLabel;

  /// 操作按钮图标（可选）
  final IconData? actionIcon;

  /// 点击操作按钮回调（可选）
  final VoidCallback? onActionPressed;

  /// 是否紧凑模式（用于列表卡片内、侧边栏、Tab 等局部小区域）
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double iconSize = compact ? 32.0 : 48.0;
    final double avatarPadding = compact ? 12.0 : 20.0;
    final double verticalPadding = compact ? 16.0 : 32.0;
    final double horizontalPadding = compact ? 12.0 : 24.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 图标徽章（软色调圆环背景）
            Container(
              padding: EdgeInsets.all(avatarPadding),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: colorScheme.primary.withValues(alpha: 0.85),
              ),
            ),
            SizedBox(height: compact ? 10 : 16),
            // 主标题
            Text(
              title,
              textAlign: TextAlign.center,
              style: (compact
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.titleMedium)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            // 副标题
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              SizedBox(height: compact ? 4 : 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: (compact
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ],
            // 行动按钮
            if (actionLabel != null && onActionPressed != null) ...[
              SizedBox(height: compact ? 12 : 20),
              actionIcon != null
                  ? FilledButton.icon(
                      onPressed: onActionPressed,
                      icon: Icon(actionIcon, size: compact ? 16 : 18),
                      label: Text(actionLabel!),
                    )
                  : FilledButton.tonal(
                      onPressed: onActionPressed,
                      child: Text(actionLabel!),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
