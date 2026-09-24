import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 在外部应用/浏览器中打开链接。
/// 打开失败时回退为复制链接到剪贴板并提示，避免链接不可用。
Future<void> openExternalUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.tryParse(url);

  if (uri != null) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // 忽略并走剪贴板回退
    }
  }

  await Clipboard.setData(ClipboardData(text: url));
  messenger.showSnackBar(
    const SnackBar(content: Text('无法打开链接，已复制到剪贴板')),
  );
}
