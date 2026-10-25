# 独立分发与发布门槛

当前候选版本为 `0.1.0-beta.1`，尚未上传 pub.dev。代码按两个包维护：

| 包 | 职责 |
| --- | --- |
| `xplayer_player` | 播放接口、源与请求头、HLS、内核策略、完整 libmpv 后端、状态和音频会话 |
| `libmpv_xplayer` | 四个平台的原生资产、固定构建清单、Darwin 视频桥接、AudioUnit 配方与 Android EGL 能力 API；Linux 传递接入系统库适配器 |

继续在同一仓库管理，避免两个包的解码库与接口版本漂移。包的生产依赖使用版本约束；Dart workspace 在仓库内解析本地版本，外部使用时按正常 hosted 依赖解析。当前没有必要再拆多个策略包或建立另一个仓库。

主应用专有的 Android SurfaceView/Activity、系统播放器设置、频道数据库、UI 和小窗交接仍由宿主拥有。外部用户可直接使用 `MediaKitBackend`，也可以按接口提供自己的后端工厂；独立示例演示直接接入。

## 仓库内开发

根目录 `pubspec.yaml` 声明原生包、核心包和示例的 workspace，统一解析和锁文件：

```sh
flutter pub get
cd packages/libmpv_xplayer
flutter test
cd ../xplayer_player
flutter analyze
flutter test
```

应用依赖 `xplayer_player: ^0.1.0-beta.1`，核心包依赖相同版本的 `libmpv_xplayer`。原生二进制继续使用精确版本和 SHA-256，不随 Dart 依赖范围浮动。

## 打包并在仓库外验证

在仓库根目录执行：

```sh
python3 tool/package_player.py --output /tmp/xplayer-player-packages --verify
# 同时检查一个实际的独立宿主构建：
python3 tool/package_player.py --output /tmp/xplayer-player-packages --verify --build macos
```

可用 `--flutter=/absolute/path/to/flutter` 选择 SDK，`--build` 支持 android、ios（模拟器）、macos、windows、linux，需要对应宿主工具链。

工具将候选源码复制到仓库外，故意改变两个包的相对目录，重新解析依赖并执行发布预检、包单测、静态检查和独立示例测试。它不会执行实际发布，也不修改本机 pub cache 或 Flutter SDK。输出包括：

- 两个源码 `.tar.gz` 和 `SHA256SUMS`；归档去掉缓存、原生大文件、个人路径与历史验收原始数据。
- `packaging-report.html`：可直接浏览的步骤结果与日志链接。
- `packaging-report.json`：供 CI 读取的状态与校验数据。

`--keep-staging` 保留临时工作区供排查；默认执行完清理。源码包归档对时间戳、所有者与文件顺序做规范化，相同源码产生相同归档字节。

两个包中的 `resolution: workspace` 是源码开发配置；正常 hosted 依赖由宿主解析。若单独解压后要直接在包目录运行 `pub get`，按 Dart workspace 规范在临时 `pubspec_overrides.yaml` 中清空 `resolution`，或将两个包加入自己的 workspace。该覆盖文件不得发布。

最低依赖检查会保留 `resolved-pubspec.lock`，且禁止示例解析偷偷升级该组合。上游范围允许的旧 `win32 4.x`、`archive 3.1.x` 使用了新 Dart 已删除的 typed-data 视图 API，故核心显式约束 `win32 >=5.5.1`、`archive >=3.6.1`；这两项是兼容下限约束。

## 独立设备验收

先按测试文档生成 36 组样本，再指定目标设备：

```sh
python3 packages/xplayer_player/tool/run_device_validation.py \
  --platform android --device emulator-5562 \
  --fixtures /tmp/xplayer-fixtures --report /tmp/xplayer-device.json
```

Android 需要 `adb`，Apple 需要 Xcode/simctl；可用 `--adb`、`--flutter` 显式指定工具。iOS 指定已启动的专用模拟器 UUID；macOS 使用 `--platform macos --device macos`。

默认自动/强制软解两种模式共 72 项。用 `--mode auto` 限定一轮，`--filter` 选样本，`--audible` 开启声音。默认静音检查不等于物理声音验收；系统混音与真机路由按测试文档另做专项。

流程负责临时样本服务、构建、安装和启动独立示例探针、逐项读取检查点、输出 JSON/HTML，并停止探针、移除自己创建的端口转发和临时入口。设备由调用者提供，不会自动清空、关闭或删除用户的设备。

CI 的 Apple 分发任务还从仓库外副本运行完整 72 项，防止视频插件被编译为空实现却仍然构建成功。根目录 `tool/verify_darwin_distribution.py` 为 iOS 创建并清理自己的模拟器。Android 使用独立模拟器执行同一矩阵。最低依赖组合通过仓库外 `--resolution lowest` 检查，应用发布依赖整套播放器质量任务成功。

## 发布顺序

1. 从提交冻结的源码运行完整测试、仓库外验证与所声明平台的设备验收。
2. 核对原生来源、通知、版本记录、SDK 下限与兼容范围。
3. 先发布 `libmpv_xplayer`，确认相应版本可从 pub.dev 安装，再发布依赖它的 `xplayer_player`。
4. 使用完全独立的宿主从 hosted 安装候选版本，执行构建与关键播放用例后再提升稳定版本。

本轮只准备候选包，不执行步骤 3 的上传。发布预检的零警告不代表 pub.dev 服务端已经接受或完成真实 hosted 安装，也不替代 Windows/Linux 真运行、真机、30 分钟/2 小时长稳与音频路由验收。
