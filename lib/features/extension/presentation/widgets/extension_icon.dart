import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ExtensionIcon extends StatelessWidget {
  const ExtensionIcon({
    super.key,
    required this.iconUrl,
    required this.size,
    this.borderRadius,
    this.iconSize,
  });

  final String? iconUrl;
  final double size;
  final double? borderRadius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Widget placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(borderRadius ?? size * 0.25),
      ),
      child: Icon(
        Icons.movie_outlined,
        size: iconSize ?? size * 0.5,
        color: colorScheme.onPrimaryContainer,
      ),
    );

    if (iconUrl == null || iconUrl!.isEmpty) {
      return placeholder;
    }

    Widget decorated(Widget child) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(borderRadius ?? size * 0.25),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

    return FutureBuilder<Uint8List?>(
      future: _loadIconMemoized(iconUrl!, size),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.hasError || bytes == null) {
          return placeholder;
        }
        return decorated(
          Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => placeholder,
          ),
        );
      },
    );
  }
}

final Map<String, Future<Uint8List?>> _iconFutures = {};

/// 缓存 future 本身：同一 URL 的并发/重复 build 复用同一次请求，
/// 避免 FutureBuilder rebuild 反复触发产生 NoSuchMethod 与死循环。
Future<Uint8List?> _loadIconMemoized(String url, double size) {
  final key = '$url#$size';
  return _iconFutures.putIfAbsent(key, () => _loadIcon(url, size));
}

Future<Uint8List?> _loadIcon(String url, double size) async {
  final key = '$url#$size';
  final cached = _iconCache[key];
  if (cached != null) {
    return cached;
  }
  try {
    final uri = Uri.parse(url);
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    final raw = resp.bodyBytes;
    if (resp.statusCode != 200) {
      return null;
    }
    final bytes = _decode(raw, size);
    if (bytes != null) {
      _iconCache[key] = bytes;
    }
    return bytes;
  } catch (_) {
    return null;
  }
}

final Map<String, Uint8List> _iconCache = {};

/// ICO 内部通常内嵌一张 PNG（或 BMP）图像，抽取出来交给 Flutter 解码。
/// GIF/JPEG/PNG/WebP/BMP 字节直接可用。
Uint8List? _decode(Uint8List bytes, double size) {
  if (bytes.length < 8) {
    return null;
  }

  if (_isSignature(bytes, 0, [0x89, 0x50, 0x4E, 0x47])) {
    return bytes; // PNG
  }
  if (_isSignature(bytes, 0, [0x47, 0x49, 0x46, 0x38])) {
    return bytes; // GIF
  }
  if (_isSignature(bytes, 0, [0xFF, 0xD8, 0xFF])) {
    return bytes; // JPEG
  }
  if (_isSignature(bytes, 0, [0x42, 0x4D])) {
    return bytes; // BMP
  }
  if (_isSignature(bytes, 0, [0x52, 0x49, 0x46, 0x46])) {
    return bytes; // WebP/RIFF
  }

  return _decodeIco(bytes, size);
}

/// ICO（含内嵌 BMP/PNG 的旧式与 Vista 格式）通过 image 包解码为 PNG。
/// 从多尺寸条目中选择最接近目标 size 的一帧，避免小图被放大发糊。
Uint8List? _decodeIco(Uint8List bytes, double size) {
  try {
    final entries = _icoEntries(bytes);
    if (entries.isEmpty) {
      return null;
    }
    // ICO 宽高用 1 字节表示，255 表 256 实际用 0
    int best = 0;
    double bestDelta = double.infinity;
    for (var i = 0; i < entries.length; i++) {
      final w = entries[i].width == 0 ? 256 : entries[i].width;
      final h = entries[i].height == 0 ? 256 : entries[i].height;
      final delta = (size - w).abs() + (size - h).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = i;
      }
    }
    final image = img.decodeIco(bytes, frame: best);
    if (image == null) {
      return null;
    }
    return img.encodePng(image);
  } catch (_) {
    return null;
  }
}

typedef _IcoEntry = ({int width, int height});

/// 解析 ICO 目录项：头部 6 字节 + 每 16 字节一个条目。
List<_IcoEntry> _icoEntries(Uint8List bytes) {
  if (bytes.length < 6) return const [];
  final data = ByteData.sublistView(bytes);
  if (data.getUint16(2, Endian.little) != 1) return const []; // ICONDIR
  final count = data.getUint16(4, Endian.little);
  final entries = <_IcoEntry>[];
  for (var i = 0; i < count; i++) {
    final base = 6 + i * 16;
    if (base + 2 > bytes.length) break;
    entries.add((width: data.getUint8(base), height: data.getUint8(base + 1)));
  }
  return entries;
}

bool _isSignature(Uint8List b, int offset, List<int> sig) {
  if (offset + sig.length > b.length) return false;
  for (var i = 0; i < sig.length; i++) {
    if (b[offset + i] != sig[i]) return false;
  }
  return true;
}