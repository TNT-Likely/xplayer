package com.tntlikely.xplayer

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.widget.FrameLayout
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 原生 ExoPlayer + SurfaceView。SurfaceView 垫在透明 FlutterView 之下(全屏 hole-punch)。
 * 命令经 MethodChannel "native_player";事件经 EventChannel "native_player/events"。
 */
class NativeVideoEngine(
    private val context: Context,
    private val container: FrameLayout,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val main = Handler(Looper.getMainLooper())
    private var player: ExoPlayer? = null
    private var surfaceView: SurfaceView? = null
    private var aspectFrame: AspectRatioFrameLayout? = null
    private var events: EventChannel.EventSink? = null
    private var positionPoller: Runnable? = null

    companion object {
        const val METHOD_CHANNEL = "native_player"
        const val EVENT_CHANNEL = "native_player/events"
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) { events = sink }
    override fun onCancel(arguments: Any?) { events = null }

    private fun emit(map: Map<String, Any?>) {
        main.post { events?.success(map) }
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setSurfaceShown" -> { setSurfaceShown(call.arguments as Boolean); result.success(null) }
            "load" -> {
                val url = call.argument<String>("url")!!
                val profile = call.argument<String>("profile") ?: "live"
                load(url, profile); result.success(null)
            }
            // 注意:必须 main.post,与 load 同队列;否则切源时 play 可能在 load(重建+prepare)之前
            // 执行,对着尚未就绪/已释放的 player 调用 → 不自动播放。
            "play" -> { main.post { player?.play() }; result.success(null) }
            "pause" -> { main.post { player?.pause() }; result.success(null) }
            "seekTo" -> { val ms = (call.argument<Int>("ms") ?: 0).toLong(); main.post { player?.seekTo(ms) }; result.success(null) }
            "release" -> { release(); result.success(null) }
            else -> result.notImplemented()
        }
    }

    private fun ensureSurface() {
        if (surfaceView != null) return
        val sv = SurfaceView(context)
        sv.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) { player?.setVideoSurface(holder.surface) }
            override fun surfaceChanged(holder: SurfaceHolder, f: Int, w: Int, h: Int) {}
            override fun surfaceDestroyed(holder: SurfaceHolder) { player?.setVideoSurface(null) }
        })
        // 用 AspectRatioFrameLayout(RESIZE_MODE_FIT)包住 SurfaceView,按视频实际比例
        // letterbox,而不是把 SurfaceView 拉满全屏导致变形(SCALE_TO_FIT 会拉伸)。
        val frame = AspectRatioFrameLayout(context)
        frame.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        frame.addView(sv, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
        container.addView(frame, 0, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT,
            android.view.Gravity.CENTER))
        surfaceView = sv
        aspectFrame = frame
    }

    private fun setSurfaceShown(shown: Boolean) {
        main.post {
            ensureSurface()
            aspectFrame?.visibility = if (shown) View.VISIBLE else View.GONE
        }
    }

    private fun bufferDurations(profile: String): IntArray = when (profile) {
        "vod" -> intArrayOf(15000, 45000, 3000, 10000)
        else -> intArrayOf(8000, 30000, 1500, 5000)
    }

    private fun load(url: String, profile: String) {
        main.post {
            ensureSurface()
            if (player == null) player = buildPlayer(profile)
            val p = player!!
            surfaceView?.holder?.surface?.let { p.setVideoSurface(it) }
            p.setMediaItem(MediaItem.fromUri(url))
            p.prepare()
        }
    }

    private fun buildPlayer(profile: String): ExoPlayer {
        val b = bufferDurations(profile)
        val renderers = DefaultRenderersFactory(context).setEnableDecoderFallback(true)
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(b[0], b[1], b[2], b[3])
            .build()
        val p = ExoPlayer.Builder(context, renderers)
            .setLoadControl(loadControl)
            .build()
        p.videoScalingMode = C.VIDEO_SCALING_MODE_SCALE_TO_FIT
        p.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                when (state) {
                    Player.STATE_READY -> {
                        emit(mapOf("event" to "initialized",
                            "width" to (p.videoSize.width), "height" to (p.videoSize.height)))
                        emit(mapOf("event" to "buffering", "value" to false))
                    }
                    Player.STATE_BUFFERING -> emit(mapOf("event" to "buffering", "value" to true))
                    else -> {}
                }
            }
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                emit(mapOf("event" to if (isPlaying) "playing" else "paused"))
            }
            override fun onVideoSizeChanged(size: VideoSize) {
                emit(mapOf("event" to "videoSizeChanged", "width" to size.width, "height" to size.height))
                // 按视频实际显示比例(含非方形像素 pixelWidthHeightRatio)设置 letterbox 比例
                if (size.width > 0 && size.height > 0) {
                    val ratio = size.width * size.pixelWidthHeightRatio / size.height
                    main.post { aspectFrame?.setAspectRatio(ratio) }
                }
            }
            override fun onPlayerError(error: PlaybackException) {
                emit(mapOf("event" to "error", "code" to error.errorCodeName, "msg" to (error.message ?: "")))
            }
        })
        startPositionPolling(p)
        return p
    }

    private fun startPositionPolling(p: ExoPlayer) {
        positionPoller?.let { main.removeCallbacks(it) }
        val r = object : Runnable {
            override fun run() {
                if (player === p) {
                    emit(mapOf("event" to "position", "ms" to p.currentPosition,
                        "duration" to (if (p.duration == C.TIME_UNSET) 0L else p.duration)))
                    main.postDelayed(this, 500)
                }
            }
        }
        positionPoller = r
        main.postDelayed(r, 500)
    }

    /** 供宿主 Activity 销毁时释放底层 ExoPlayer / SurfaceView。 */
    fun dispose() { release() }

    private fun release() {
        main.post {
            positionPoller?.let { main.removeCallbacks(it) }
            player?.release(); player = null
            aspectFrame?.let { container.removeView(it) }
            aspectFrame = null
            surfaceView = null
        }
    }
}
