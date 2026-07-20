package de.loicezt.stickers.gif

import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.os.SystemClock
import android.view.View
import android.widget.ImageView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import pl.droidsonroids.gif.GifDrawable
import pl.droidsonroids.gif.GifImageView
import java.io.File

const val GIF_PREVIEW_VIEW_TYPE = "de.loicezt.stickers/gif_preview"

data class GifPreviewRange(val startMs: Int, val endMs: Int) {
    init {
        require(startMs >= 0) { "Start time must not be negative" }
        require(endMs > startMs) { "End time must be after start time" }
    }

    fun positionAt(elapsedMs: Long): Int {
        require(elapsedMs >= 0) { "Elapsed time must not be negative" }
        val selectedDuration = endMs - startMs
        return startMs + (elapsedMs % selectedDuration).toInt()
    }

    companion object {
        fun clamp(startMs: Int, endMs: Int, durationMs: Int): GifPreviewRange {
            require(durationMs > 0) { "GIF duration must be positive" }
            val start = startMs.coerceIn(0, durationMs - 1)
            val end = endMs.coerceIn(start + 1, durationMs)
            return GifPreviewRange(start, end)
        }
    }
}

class GifPreviewViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return GifPreviewPlatformView(context, messenger, viewId, args)
    }
}

private class GifPreviewPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    creationParams: Any?,
) : PlatformView {
    private val imageView = GifImageView(context)
    private val drawable: GifDrawable
    private val channel = MethodChannel(messenger, "$GIF_PREVIEW_VIEW_TYPE/$viewId")
    private val mainHandler = Handler(Looper.getMainLooper())
    private val playbackThread = HandlerThread("gif-trim-preview-$viewId").apply { start() }
    private val playbackHandler = Handler(playbackThread.looper)
    private val drawableLock = Any()

    @Volatile
    private var playback: GifPreviewPlayback

    @Volatile
    private var positionMs: Int

    @Volatile
    private var disposed = false

    private val rangeLoop = object : Runnable {
        override fun run() {
            if (disposed) return

            val frameStartedAt = SystemClock.uptimeMillis()
            val currentPlayback = playback
            val targetPosition = currentPlayback.range.positionAt(
                (frameStartedAt - currentPlayback.startedAtMs).coerceAtLeast(0),
            )
            synchronized(drawableLock) {
                if (disposed) return
                drawable.seekToBlocking(targetPosition)
            }
            positionMs = targetPosition
            mainHandler.post {
                if (!disposed) imageView.invalidate()
            }

            if (!disposed) {
                val renderTime = SystemClock.uptimeMillis() - frameStartedAt
                playbackHandler.postDelayed(
                    this,
                    (previewFrameIntervalMs - renderTime).coerceAtLeast(1),
                )
            }
        }
    }

    init {
        val params = creationParams as? Map<*, *>
            ?: throw IllegalArgumentException("GIF preview arguments must be a map")
        val gifFile = params.requiredString("gifFile")
        drawable = GifDrawable(File(gifFile))
        val initialRange = GifPreviewRange.clamp(
            params.requiredInt("startMs"),
            params.requiredInt("endMs"),
            drawable.duration,
        )
        playback = GifPreviewPlayback(initialRange, SystemClock.uptimeMillis())
        positionMs = initialRange.startMs

        imageView.setBackgroundColor(Color.TRANSPARENT)
        imageView.scaleType = ImageView.ScaleType.CENTER_INSIDE
        drawable.stop()
        imageView.setImageDrawable(drawable)

        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "setRange" -> {
                        val arguments = call.arguments as? Map<*, *>
                            ?: throw IllegalArgumentException("Range arguments must be a map")
                        val range = GifPreviewRange.clamp(
                            arguments.requiredInt("startMs"),
                            arguments.requiredInt("endMs"),
                            drawable.duration,
                        )
                        restartPlayback(range)
                        result.success(null)
                    }

                    "getPosition" -> result.success(positionMs)
                    else -> result.notImplemented()
                }
            } catch (error: IllegalArgumentException) {
                result.error("INVALID_GIF_PREVIEW_RANGE", error.message, null)
            }
        }
        playbackHandler.post(rangeLoop)
    }

    override fun getView(): View = imageView

    override fun dispose() {
        disposed = true
        playbackHandler.removeCallbacks(rangeLoop)
        channel.setMethodCallHandler(null)
        imageView.setImageDrawable(null)
        synchronized(drawableLock) {
            drawable.recycle()
        }
        playbackThread.quitSafely()
    }

    private fun restartPlayback(range: GifPreviewRange) {
        playback = GifPreviewPlayback(range, SystemClock.uptimeMillis())
        positionMs = range.startMs
        playbackHandler.removeCallbacks(rangeLoop)
        playbackHandler.post(rangeLoop)
    }
}

private data class GifPreviewPlayback(
    val range: GifPreviewRange,
    val startedAtMs: Long,
)

private const val previewFrameIntervalMs = 33L

private fun Map<*, *>.requiredString(key: String): String {
    val value = this[key] as? String
        ?: throw IllegalArgumentException("$key must be a string")
    require(value.isNotBlank()) { "$key must not be blank" }
    return value
}

private fun Map<*, *>.requiredInt(key: String): Int {
    val value = this[key] as? Number
        ?: throw IllegalArgumentException("$key must be a number")
    val number = value.toDouble()
    require(number.isFinite() && number % 1.0 == 0.0) { "$key must be an integer" }
    require(number >= Int.MIN_VALUE && number <= Int.MAX_VALUE) {
        "$key is outside the integer range"
    }
    return number.toInt()
}
