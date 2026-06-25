import 'package:xplayer/data/models/channel_model.dart';

const int kRecentMax = 20;

/// 把 [played] 合并进最近列表:按 id 去重、置于队首、裁剪到 [max]。返回新列表。
List<Channel> mergeRecent(List<Channel> current, Channel played,
    {int max = kRecentMax}) {
  final out = <Channel>[played];
  for (final c in current) {
    if (c.id == played.id) continue;
    out.add(c);
  }
  if (out.length > max) return out.sublist(0, max);
  return out;
}
