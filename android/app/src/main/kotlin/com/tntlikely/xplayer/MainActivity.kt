package com.tntlikely.xplayer

import android.media.MediaCodecList
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val diagChannel = "diag/logcat"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, diagChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLogcat" -> {
                        try {
                            result.success(readLogcat())
                        } catch (e: Exception) {
                            result.error("LOGCAT_ERR", e.message, null)
                        }
                    }
                    "getCodecs" -> {
                        try {
                            result.success(probeCodecs())
                        } catch (e: Exception) {
                            result.error("CODEC_ERR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // 读取本应用最近的 logcat(-d:dump 后退出;-t:最后 N 行)。
    // 普通应用经 exec 调 logcat 只能拿到自身 uid 的日志,正好含我们 pid 下的 MediaCodec 解码器行。
    private fun readLogcat(): String {
        val process = Runtime.getRuntime()
            .exec(arrayOf("logcat", "-d", "-v", "time", "-t", "3000"))
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val sb = StringBuilder()
        var line: String? = reader.readLine()
        while (line != null) {
            sb.append(line).append('\n')
            line = reader.readLine()
        }
        reader.close()
        return sb.toString()
    }

    // 不需任何权限:枚举 MediaCodec 解码器,判定常见视频编码是否有硬件解码器。
    // 用于在无法读 logcat 的设备(电视/受限系统)上排查「硬解是否存在/被回退」。
    private fun probeCodecs(): String {
        val sb = StringBuilder()
        sb.append("设备: ${Build.MANUFACTURER} ${Build.MODEL}  Android API=${Build.VERSION.SDK_INT}\n")
        sb.append("[HW]=硬件解码器  [SW]=软件解码器  (CCTV 等直播通常是 H.264/video-avc 或 H.265/video-hevc)\n\n")
        val mimes = listOf(
            "video/avc" to "H.264",
            "video/hevc" to "H.265",
            "video/mpeg2" to "MPEG-2",
            "video/x-vnd.on2.vp9" to "VP9",
            "video/av01" to "AV1"
        )
        val list = MediaCodecList(MediaCodecList.ALL_CODECS)
        for ((mime, label) in mimes) {
            sb.append("== $label ($mime) ==\n")
            var found = false
            for (info in list.codecInfos) {
                if (info.isEncoder) continue
                if (info.supportedTypes.none { it.equals(mime, ignoreCase = true) }) continue
                found = true
                val name = info.name
                val hw = if (Build.VERSION.SDK_INT >= 29) {
                    info.isHardwareAccelerated
                } else {
                    !(name.startsWith("OMX.google", true) || name.startsWith("c2.android", true))
                }
                var dims = ""
                try {
                    val vc = info.getCapabilitiesForType(mime).videoCapabilities
                    if (vc != null) {
                        dims = "  max ${vc.supportedWidths.upper}x${vc.supportedHeights.upper}"
                    }
                } catch (_: Exception) {
                }
                sb.append("  ${if (hw) "[HW]" else "[SW]"} $name$dims\n")
            }
            if (!found) sb.append("  (无解码器)\n")
            sb.append("\n")
        }
        return sb.toString()
    }
}
