import 'dart:async';
import 'dart:io';

/// HLS master 清单里的一个码率变体。
class HlsVariant {
  final int? bandwidth; // bits/s(BANDWIDTH 或 AVERAGE-BANDWIDTH)
  final int? width;
  final int? height;
  final String? codecs;
  final String? frameRate;

  /// 该变体的媒体清单绝对地址(选定画质时直接播这个 → ExoPlayer 锁定该档不再 ABR)
  final String url;

  const HlsVariant({
    required this.url,
    this.bandwidth,
    this.width,
    this.height,
    this.codecs,
    this.frameRate,
  });

  /// 画质档位标签:4K / 1080P / 720P …(按高度)
  String get qualityLabel {
    final h = height;
    if (h == null) return resolution ?? '?';
    if (h >= 2160) return '4K';
    return '${h}P';
  }

  /// "4.9 Mbps" / "840 kbps"
  String get bandwidthLabel {
    final b = bandwidth;
    if (b == null || b <= 0) return '';
    return b >= 1000000
        ? '${(b / 1000000).toStringAsFixed(1)} Mbps'
        : '${b ~/ 1000} kbps';
  }

  /// "1920x1080" 或 null
  String? get resolution =>
      (width != null && height != null) ? '${width}x$height' : null;

  /// 取较短边作为"线数"(与播放器信息栏分辨率档对齐)
  int? get lines {
    if (width == null || height == null) return null;
    return width! < height! ? width! : height!;
  }

  String get bitrateLabel =>
      bandwidth != null && bandwidth! > 0 ? '${bandwidth! ~/ 1000} kbps' : '—';
}

/// 探测结果。
class HlsProbeResult {
  /// 是否为 master 清单(含多变体)
  final bool isMaster;

  /// 解析出的变体(已按带宽降序);非 master 时为空
  final List<HlsVariant> variants;

  /// 不是 HLS(直链 mp4/ts/rtmp 等)
  final bool notHls;

  /// 探测失败的错误信息
  final String? error;

  const HlsProbeResult({
    this.isMaster = false,
    this.variants = const [],
    this.notHls = false,
    this.error,
  });

  /// 最高分辨率变体(按线数,其次带宽)
  HlsVariant? get best {
    if (variants.isEmpty) return null;
    final sorted = [...variants]..sort((a, b) {
        final la = a.lines ?? 0, lb = b.lines ?? 0;
        if (la != lb) return lb - la;
        return (b.bandwidth ?? 0) - (a.bandwidth ?? 0);
      });
    return sorted.first;
  }
}

/// 拉取并解析 HLS master 清单,列出所有码率变体。
///
/// 用途:验证"画面模糊是否因为 ExoPlayer 自适应选了低清档"——
/// 把这里列出的最高变体分辨率,和信息栏正在播的分辨率对比即可定方向。
Future<HlsProbeResult> probeHlsVariants(
  String url, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final lower = url.toLowerCase();
  if (!lower.contains('.m3u8')) {
    return const HlsProbeResult(notHls: true);
  }

  final client = HttpClient();
  client.connectionTimeout = timeout;
  client.badCertificateCallback = (cert, host, port) => true; // IPTV 常用自签证书
  try {
    final req = await client.getUrl(Uri.parse(url.trim())).timeout(timeout);
    req.headers.set(HttpHeaders.userAgentHeader, 'XPlayer');
    final resp = await req.close().timeout(timeout);
    if (resp.statusCode < 200 || resp.statusCode >= 400) {
      return HlsProbeResult(error: 'HTTP ${resp.statusCode}');
    }

    final buf = StringBuffer();
    await for (final chunk in resp.timeout(timeout)) {
      buf.write(String.fromCharCodes(chunk));
      if (buf.length > 262144) break; // master 清单很小,256KB 足够
    }
    final text = buf.toString();
    if (!text.contains('#EXTM3U')) {
      return const HlsProbeResult(error: '非标准 m3u8');
    }
    if (!text.contains('#EXT-X-STREAM-INF')) {
      // media 播放列表(单档),没有多变体可选
      return const HlsProbeResult(isMaster: false);
    }

    final variants = _parseStreamInf(text, Uri.parse(url.trim()));
    variants.sort((a, b) => (b.bandwidth ?? 0) - (a.bandwidth ?? 0));
    return HlsProbeResult(isMaster: true, variants: variants);
  } on TimeoutException {
    return const HlsProbeResult(error: '超时');
  } catch (e) {
    return HlsProbeResult(error: e.toString());
  } finally {
    client.close(force: true);
  }
}

List<HlsVariant> _parseStreamInf(String text, Uri baseUri) {
  final out = <HlsVariant>[];
  final lines = text.split(RegExp(r'\r?\n'));
  for (int i = 0; i < lines.length; i++) {
    final t = lines[i].trim();
    if (!t.startsWith('#EXT-X-STREAM-INF:')) continue;
    final attrs = t.substring('#EXT-X-STREAM-INF:'.length);
    // URI 是紧随其后的第一个非空、非注释行
    String? uri;
    for (int j = i + 1; j < lines.length; j++) {
      final u = lines[j].trim();
      if (u.isEmpty || u.startsWith('#')) continue;
      uri = u;
      break;
    }
    if (uri == null) continue; // 没有对应媒体清单地址,跳过
    final abs = baseUri.resolve(uri).toString();
    out.add(HlsVariant(
      url: abs,
      bandwidth: _parseInt(_attr(attrs, 'AVERAGE-BANDWIDTH')) ??
          _parseInt(_attr(attrs, 'BANDWIDTH')),
      width: _parseRes(attrs)?.$1,
      height: _parseRes(attrs)?.$2,
      codecs: _attr(attrs, 'CODECS')?.replaceAll('"', ''),
      frameRate: _attr(attrs, 'FRAME-RATE'),
    ));
  }
  return out;
}

/// 取属性值;支持带引号的值(CODECS="...")
String? _attr(String attrs, String key) {
  // 匹配 KEY=value(value 可带引号,内部不含逗号或被引号包裹)
  final re = RegExp('(?:^|,)\\s*$key=("[^"]*"|[^,]*)');
  final m = re.firstMatch(attrs);
  return m?.group(1)?.trim();
}

(int, int)? _parseRes(String attrs) {
  final v = _attr(attrs, 'RESOLUTION');
  if (v == null) return null;
  final parts = v.split('x');
  if (parts.length != 2) return null;
  final w = int.tryParse(parts[0].trim());
  final h = int.tryParse(parts[1].trim());
  if (w == null || h == null) return null;
  return (w, h);
}

int? _parseInt(String? v) => v == null ? null : int.tryParse(v.trim());
