/// 编译期构建开关。
///
/// [kStoreBuild]:应用商店(App Store / Google Play)构建。
/// 为通过审核,商店包做成「纯播放器」—— 不内置任何直播源:
///   - 不自动种入默认源(中国 cn.m3u);
///   - 不显示「推荐源」入口(首页抽屉、空状态按钮)。
/// 用户需自行导入 M3U。
///
/// 开启方式(CI 里):`flutter build ... --dart-define=STORE_BUILD=true`。
/// 默认 false —— GitHub 直接下载的包(侧载)保留内置源,体验不变。
const bool kStoreBuild = bool.fromEnvironment('STORE_BUILD', defaultValue: false);
