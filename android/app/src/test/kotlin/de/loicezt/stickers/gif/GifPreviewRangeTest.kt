package de.loicezt.stickers.gif

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class GifPreviewRangeTest {
    @Test
    fun `keeps a valid selected range`() {
        assertEquals(GifPreviewRange(1200, 4800), GifPreviewRange.clamp(1200, 4800, 8000))
    }

    @Test
    fun `clamps a selected range to the GIF duration`() {
        assertEquals(GifPreviewRange(7999, 8000), GifPreviewRange.clamp(9000, 10000, 8000))
    }

    @Test
    fun `loops elapsed playback within the selected range`() {
        val range = GifPreviewRange(1000, 3600)

        assertEquals(1000, range.positionAt(0))
        assertEquals(3599, range.positionAt(2599))
        assertEquals(1000, range.positionAt(2600))
        assertEquals(2000, range.positionAt(3600))
    }

    @Test
    fun `rejects a GIF without positive duration`() {
        assertThrows(IllegalArgumentException::class.java) {
            GifPreviewRange.clamp(0, 1, 0)
        }
    }
}
