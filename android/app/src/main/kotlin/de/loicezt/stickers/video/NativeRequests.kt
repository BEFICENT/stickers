package de.loicezt.stickers.video

data class TrimRequest(
    val requestId: String,
    val inputFile: String,
    val outputFile: String,
    val startTimeUs: Long,
    val endTimeUs: Long,
) {
    companion object {
        fun from(arguments: Any?): TrimRequest {
            val args = NativeArguments(arguments)
            val request = TrimRequest(
                requestId = args.string("requestId"),
                inputFile = args.string("inputFile"),
                outputFile = args.string("outputFile"),
                startTimeUs = args.long("startTimeUs"),
                endTimeUs = args.long("endTimeUs"),
            )
            require(request.startTimeUs >= 0) { "startTimeUs must be non-negative" }
            require(request.endTimeUs > request.startTimeUs) {
                "endTimeUs must be greater than startTimeUs"
            }
            return request
        }
    }
}

data class VideoOverlayRequest(
    val requestId: String,
    val videoFile: String,
    val overlayFile: String,
    val outputFile: String,
    val config: WebPConfig,
    val fps: Int,
) {
    companion object {
        fun from(arguments: Any?): VideoOverlayRequest {
            val args = NativeArguments(arguments)
            return VideoOverlayRequest(
                requestId = args.string("requestId"),
                videoFile = args.string("videoFile"),
                overlayFile = args.string("overlayFile"),
                outputFile = args.string("outputFile"),
                config = WebPConfig.fromMap(args.map("config")),
                fps = args.fps(),
            )
        }
    }
}

data class GifOverlayRequest(
    val requestId: String,
    val gifFile: String,
    val overlayFile: String,
    val outputFile: String,
    val startMs: Int,
    val endMs: Int,
    val config: WebPConfig,
    val fps: Int,
) {
    companion object {
        fun from(arguments: Any?): GifOverlayRequest {
            val args = NativeArguments(arguments)
            val request = GifOverlayRequest(
                requestId = args.string("requestId"),
                gifFile = args.string("gifFile"),
                overlayFile = args.string("overlayFile"),
                outputFile = args.string("outputFile"),
                startMs = args.int("startMs"),
                endMs = args.int("endMs"),
                config = WebPConfig.fromMap(args.map("config")),
                fps = args.fps(),
            )
            require(request.startMs >= 0) { "startMs must be non-negative" }
            require(request.endMs > request.startMs) {
                "endMs must be greater than startMs"
            }
            return request
        }
    }
}

private class NativeArguments(arguments: Any?) {
    private val values = arguments as? Map<*, *>
        ?: throw IllegalArgumentException("Arguments must be a map")

    fun string(key: String): String {
        val value = values[key] as? String
            ?: throw IllegalArgumentException("$key must be a string")
        require(value.isNotBlank()) { "$key must not be blank" }
        return value
    }

    fun int(key: String): Int {
        val value = integralNumber(key)
        require(value in Int.MIN_VALUE..Int.MAX_VALUE) { "$key is outside the integer range" }
        return value.toInt()
    }

    fun long(key: String): Long = integralNumber(key)

    fun map(key: String): Map<*, *> = values[key] as? Map<*, *>
        ?: throw IllegalArgumentException("$key must be a map")

    fun fps(): Int = int("fps").also {
        require(it in 1..60) { "fps must be between 1 and 60" }
    }

    private fun number(key: String): Number = values[key] as? Number
        ?: throw IllegalArgumentException("$key must be a number")

    private fun integralNumber(key: String): Long {
        val value = number(key).toDouble()
        require(value.isFinite() && value % 1.0 == 0.0) {
            "$key must be a finite integer"
        }
        require(value >= Long.MIN_VALUE.toDouble() && value < Long.MAX_VALUE.toDouble()) {
            "$key is outside the long integer range"
        }
        return value.toLong()
    }
}
