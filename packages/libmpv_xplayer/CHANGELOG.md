## 0.1.0-beta.1

- 将四个本地原生适配器合并为自包含插件，使用独立注册名称与随包构建清单。
- 保留完整解码构建、固定 SHA-256、iOS 模拟器 AudioUnit 与 Android EGL 兼容探测。
- 保留 Android helper 的 JNI ABI，以及 Windows 视频插件需要的构建顺序和目录布局。
- 自带固定版本的 Darwin Swift 视频桥接，避免更换包名后上游编译成空实现。
- macOS 无法建立 OpenGL 像素格式、上下文、纹理缓存或渲染器时释放已建资源并回退软件纹理，避免虚拟机和受限图形环境直接崩溃。
- Linux 通过发行版 libmpv 与上游 Linux 适配包接入。
