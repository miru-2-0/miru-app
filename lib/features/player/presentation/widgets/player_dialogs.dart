import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miru/app/l10n/l10n_extension.dart';

/// 视频详情弹窗：片名 / 当前剧集 / 播放地址（可点击复制）
Future<void> showVideoInfoDialog(
  BuildContext context, {
  required String title,
  required String episodeName,
  required String mediaUrl,
  required VoidCallback onCopied,
}) {
  final l10n = context.l10n;

  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Colors.white12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: SingleChildScrollView(
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
                      Expanded(
                        child: Text(
                          l10n.videoDetail,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.close,
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
                _InfoRow(label: l10n.mediaTitleLabel, value: title),
                const Divider(height: 1, color: Colors.white12),
                _InfoRow(label: l10n.currentEpisodeLabel, value: episodeName),
                const Divider(height: 1, color: Colors.white12),
                _InfoRow(
                  label: l10n.mediaUrlLabel,
                  value: mediaUrl,
                  mono: true,
                  copyable: true,
                  onCopied: onCopied,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 播放错误详情弹窗
Future<void> showVideoErrorDialog(BuildContext context, String message) {
  final l10n = context.l10n;

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.errorMessageTitle),
      content: SelectableText(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

/// 详情弹窗内的单行信息（可选等宽字体与复制）
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.copyable = false,
    this.onCopied,
  });

  final String label;
  final String value;
  final bool mono;
  final bool copyable;
  final VoidCallback? onCopied;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    void copy() {
      Clipboard.setData(ClipboardData(text: value));
      onCopied?.call();
    }

    // 仅复制按钮可点，整行不响应、不高亮
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? l10n.none : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            IconButton(
              tooltip: l10n.copyMediaUrl,
              onPressed: copy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                Icons.content_copy_rounded,
                size: 16,
                color: scheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}
