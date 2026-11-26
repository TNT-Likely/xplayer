# 专用测试应用的播放列表

2026-10-25，按用户要求为专用手机、iPad 和 Android TV 模拟器加入两份列表：

- 局域网 IPTV：本轮读取到 538 个合并后频道，地址只保存在本地测试清单与设备中。
- FLV 测试（虎牙 / B站）：从当前 `flv-test.m3u` 导入 2 个频道，复制到设备文档目录的 `qa/flv-test.m3u`，并选为当前列表。

原有列表保留。添加流程使用真实 PlaylistRepository、M3U 解析与缓存；按名称或 URL 更新，重复执行不会叠加同名测试列表。临时服务只用于导入文件，完成后停止；正常应用切换列表不依赖该服务。FLV 地址签名过期后需要重新生成并导入。

三端导入与管理页检查均通过。随后覆盖安装正常 `lib/main.dart` 入口，重新启动并核对数据库、538 / 2 个频道缓存、当前列表选择以及设备内 FLV 文件的 SHA-256；结果见 [重启检查记录](qa-playlists.json)。iOS 覆盖安装时文档容器路径发生变化，本轮已将专用 QA 列表的本地文件 URI 更新到当前容器；该步骤仅调整两台专用模拟器的数据。

交接时按用户要求删除上述专用测试设备及临时清单，历史验收记录保留；重建方法见 [交接入口](../HANDOFF.md)。用户已索要的本地配置交付包保留。

## 复现

本地清单是 JSON 数组。远程列表包含 `name`、`url`；本地 FLV 包含 `name`、`file: "/flv-test.m3u"` 和可选的 `expectedChannels: 2`。清单与短效 URL 不提交到源码，交付包内的 `test-playlists.json` 为用户的实际配置。

```sh
python3 tool/live_source_fixture_server.py --root /path/to/private-qa-files \
  --playlists /path/to/private-manifest.json --port-file .dart_tool/qa-server.json
flutter drive --no-pub --keep-app-running -d '<专用模拟器 ID>' \
  --driver=test_driver/v3_driver.dart --target=integration_test/qa_playlists_test.dart \
  --dart-define=QA_DEVICE=phone \
  --dart-define=QA_PLAYLISTS_MANIFEST=http://127.0.0.1:PORT/playlists.json
```

Android 使用 `QA_DEVICE=tv` 和 `http://10.0.2.2:PORT/playlists.json`，iPad 使用 `QA_DEVICE=ipad`。完成后重建正常 `lib/main.dart` 入口并覆盖安装；iOS 若变更文档容器路径，需要同步更新 QA 本地文件 URI。再验证保存的列表、频道缓存和本地文件仍可读取。

必须保留 `--keep-app-running`：Flutter drive 默认结束流程会停止并卸载被测应用，连同数据一起清理。该参数用于保留专用测试数据；后续覆盖安装正常入口，不能再卸载重装。会清库的验收流程应使用其他临时设备，或完成后重新导入。
