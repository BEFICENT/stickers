package de.loicezt.stickers

import de.loicezt.stickers.video.CropAndScale
import de.loicezt.stickers.video.GifOverlayRequest
import de.loicezt.stickers.video.OverlayAndEncode
import de.loicezt.stickers.video.TrimRequest
import de.loicezt.stickers.video.VideoOverlayRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import java.io.File

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL_NAME = "de.loicezt.stickers/methods"
    private val TRIM_CHANNEL_NAME = "de.loicezt.stickers/progress_trim"
    private val ECODE_CHANNEL_NAME = "de.loicezt.stickers/progress_encode"

    private lateinit var cropAndScale: CropAndScale
    private lateinit var overlayAndEncode: OverlayAndEncode
    private val scope = CoroutineScope(
        Dispatchers.Main + SupervisorJob()
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        cropAndScale = CropAndScale()
        overlayAndEncode = OverlayAndEncode()

        // 1. Setup the MethodChannel to receive commands from Flutter
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTrim" -> {
                    try {
                        val request = TrimRequest.from(call.arguments)
                        cropAndScale.start(
                            request.requestId,
                            File(request.inputFile),
                            File(request.outputFile),
                            request.startTimeUs,
                            request.endTimeUs,
                            24
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        result.error(
                            "TRIM_START_FAILED",
                            e.message ?: "Could not start video trimming.",
                            null
                        )
                    }
                }

                "startOverlay" -> {
                    try {
                        val request = VideoOverlayRequest.from(call.arguments)
                        overlayAndEncode.start(
                            request.requestId,
                            File(request.videoFile),
                            File(request.overlayFile),
                            File(request.outputFile),
                            request.config,
                            request.fps
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        result.error(
                            "ENCODE_START_FAILED",
                            e.message ?: "Could not start animated export.",
                            null
                        )
                    }
                }

                "startGifOverlay" -> {
                    try {
                        val request = GifOverlayRequest.from(call.arguments)
                        overlayAndEncode.startGif(
                            request.requestId,
                            File(request.gifFile),
                            File(request.overlayFile),
                            File(request.outputFile),
                            request.startMs,
                            request.endMs,
                            request.config,
                            request.fps
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        result.error(
                            "ENCODE_START_FAILED",
                            e.message ?: "Could not start GIF export.",
                            null
                        )
                    }
                }

                "cancelOverlay" -> {
                    overlayAndEncode.cancel()
                    result.success(null)
                }

                "cancelTrim" -> {
                    cropAndScale.cancel()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        // 2. Setup the EventChannel to stream updates to Flutter
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TRIM_CHANNEL_NAME
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var eventScope: CoroutineScope? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null) return
                    // Combine both state and progress flows into a single stream
                    eventScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
                    eventScope?.launch {
                        combine(
                            cropAndScale.status,
                            cropAndScale.progress,
                            cropAndScale.requestId
                        ) { status, progress, requestId ->
                            mapOf(
                                "requestId" to requestId,
                                "status" to status.name,
                                "progress" to progress.progress,
                                "currentFrame" to progress.currentFrame,
                                "totalFrames" to progress.totalFrames
                            )
                        }.collect { update ->
                            events.success(update)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventScope?.cancel()
                    eventScope = null
                }
            }
        )
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ECODE_CHANNEL_NAME
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var eventScope: CoroutineScope? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null) return

                    eventScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
                    eventScope?.launch {
                        combine(
                            overlayAndEncode.status,
                            overlayAndEncode.progress,
                            overlayAndEncode.requestId
                        ) { status, progress, requestId ->
                            mapOf(
                                "requestId" to requestId,
                                "status" to status.name,
                                "progress" to progress.progress,
                                "currentFrame" to progress.currentFrame,
                                "totalFrames" to progress.totalFrames
                            )
                        }.collect { update ->
                            events.success(update)
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventScope?.cancel()
                    eventScope = null
                }
            }
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        cropAndScale.release()
        overlayAndEncode.release()
        scope.cancel()
    }
}

