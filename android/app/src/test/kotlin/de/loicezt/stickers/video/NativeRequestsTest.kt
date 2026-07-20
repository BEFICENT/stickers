package de.loicezt.stickers.video

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class NativeRequestsTest {
    @Test
    fun `trim request accepts MethodChannel number representations`() {
        val request = TrimRequest.from(
            mapOf(
                "requestId" to "request",
                "inputFile" to "input.mp4",
                "outputFile" to "output.mp4",
                "startTimeUs" to 1000,
                "endTimeUs" to 2500L,
            ),
        )

        assertEquals(1000L, request.startTimeUs)
        assertEquals(2500L, request.endTimeUs)
    }

    @Test
    fun `GIF request rejects an invalid range`() {
        assertThrows(IllegalArgumentException::class.java) {
            GifOverlayRequest.from(
                mapOf(
                    "requestId" to "request",
                    "gifFile" to "input.gif",
                    "overlayFile" to "overlay.webp",
                    "outputFile" to "output.webp",
                    "startMs" to 500,
                    "endMs" to 500,
                    "config" to emptyMap<String, Any>(),
                    "fps" to 24,
                ),
            )
        }
    }

    @Test
    fun `video request rejects missing required arguments`() {
        assertThrows(IllegalArgumentException::class.java) {
            VideoOverlayRequest.from(emptyMap<String, Any>())
        }
    }

    @Test
    fun `video request rejects out of range fps`() {
        assertThrows(IllegalArgumentException::class.java) {
            VideoOverlayRequest.from(
                mapOf(
                    "requestId" to "request",
                    "videoFile" to "input.mp4",
                    "overlayFile" to "overlay.webp",
                    "outputFile" to "output.webp",
                    "config" to emptyMap<String, Any>(),
                    "fps" to 0,
                ),
            )
        }
    }

    @Test
    fun `request rejects fractional integer arguments`() {
        assertThrows(IllegalArgumentException::class.java) {
            TrimRequest.from(
                mapOf(
                    "requestId" to "request",
                    "inputFile" to "input.mp4",
                    "outputFile" to "output.mp4",
                    "startTimeUs" to 1.5,
                    "endTimeUs" to 2500,
                ),
            )
        }
    }
}
