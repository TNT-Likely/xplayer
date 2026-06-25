/// URL 相关工具。
library;

/// 判断一个流地址的 host 是否为 IPv6 字面量。
///
/// 标准 IPv6 URL 形如 `http://[2409:8087::1]:8080/live.m3u8`,
/// `Uri.parse` 解析后 host 去掉方括号、保留冒号(如 `2409:8087::1`),
/// 因此用 host 是否含 `:` 判定即可。解析失败或为域名/IPv4 时返回 false。
bool isIpv6Url(String? url) {
  if (url == null || url.isEmpty) return false;
  try {
    final host = Uri.parse(url.trim()).host;
    // IPv6 字面量的 host 含冒号;域名 / IPv4 不含冒号。
    return host.contains(':');
  } catch (_) {
    return false;
  }
}
