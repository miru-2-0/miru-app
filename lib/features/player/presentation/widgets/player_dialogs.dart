import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 视频详情弹窗：片名 / 当前剧集 / 播放地址（可点击复制）
Future<void> showVideoInfoDialog(
  BuildContext context, {
  required String title,
  required String episodeName,
  required String mediaUrl,
  required VoidCallback onCopied,
}) {
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
                _InfoRow(label: '片名', value: title),
                const Divider(height: 1, color: Colors.white12),
                _InfoRow(label: '当前剧集', value: episodeName),
                const Divider(height: 1, color: Colors.white12),
                _InfoRow(
                  label: '播放地址',
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
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('错误信息'),
      content: SelectableText(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: copyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              onCopied?.call();
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
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '（无）' : value,
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
}
