package com.tntlikely.xplayer

import android.media.MediaCodecList
import android.os.Build
import androidx.media3.common.util.Log as Media3Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val diagChannel = "diag/logcat"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 提升 Media3(video_player 底层 ExoPlayer)日志级别,诊断时多透出内部 debug
        // (格式切换、解码器复用/回退、丢帧、缓冲原因等)。系统级 ACodec/MediaCodec 日志不受此影响,始终有。
        Media3Log.setLogLevel(Media3Log.LOG_LEVEL_ALL)
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
        val mimes = listOf(
            "video/avc" to "H.264",
            "video/hevc" to "H.265",
            "video/mpeg2" to "MPEG-2",
            "video/x-vnd.on2.vp9" to "VP9",
            "video/av01" to "AV1"
        )
        val list = MediaCodecList(MediaCodecList.ALL_CODECS)
        val detail = StringBuilder()
        val summary = StringBuilder()
        for ((mime, label) in mimes) {
            detail.append("== $label ($mime) ==\n")
            var found = false
            var hasHw = false
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
                if (hw) hasHw = true
                var dims = ""
                try {
                    val vc = info.getCapabilitiesForType(mime).videoCapabilities
                    if (vc != null) {
                        dims = "  max ${vc.supportedWidths.upper}x${vc.supportedHeights.upper}"
                    }
                } catch (_: Exception) {
                }
                detail.append("  ${if (hw) "[HW]" else "[SW]"} $name$dims\n")
            }
            if (!found) detail.append("  (无解码器)\n")
            detail.append("\n")
            // 仅直播最常见的 H.264 / H.265 进结论
            if (mime == "video/avc" || mime == "video/hevc") {
                val verdict = when {
                    !found -> "—(本机无此解码器)"
                    hasHw -> "✅ 有硬件解码器"
                    else -> "❌ 仅软件解码器(无硬解)"
                }
                summary.append("  $label: $verdict\n")
            }
        }

        val sb = StringBuilder()
        sb.append("设备: ${Build.MANUFACTURER} ${Build.MODEL}  Android API=${Build.VERSION.SDK_INT}\n\n")
        sb.append("【结论】直播常用编码的硬解能力:\n")
        sb.append(summary)
        sb.append("  → 有硬解时 ExoPlayer 默认就走硬解;若画面仍模糊/卡顿,\n")
        sb.append("    多半是渲染路径(Flutter 纹理绕过显示引擎 VPP)或直播源本身,\n")
        sb.append("    而非\"没有硬解能力\"。若这里显示 ❌ 仅软解,才是硬解缺失的实锤。\n\n")
        sb.append("【图例】[HW]=厂商硬件解码器(如 c2.qti./OMX.qcom./OMX.MTK./c2.amlogic.)\n")
        sb.append("        [SW]=系统软件解码器(c2.android./OMX.google.,CPU 解码,无 VPP/锐化)\n")
        sb.append("        .secure=DRM 加密流  .low_latency=低延迟  max=最大支持分辨率\n\n")
        sb.append("----- 详细列表 -----\n\n")
        sb.append(detail)
        return sb.toString()
    }
}
