package de.loicezt.stickers.video

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WebPConfigTest {
    @Test
    fun `fromMap converts the Flutter channel representation`() {
        val config = WebPConfig.fromMap(
            mapOf(
                "lossless" to false,
                "quality" to 61.5,
                "method" to 4,
                "imageHint" to "photo",
                "autofilter" to true,
                "exact" to false,
            ),
        )

        assertEquals(false, config.lossless)
        assertEquals(61.5f, config.quality)
        assertEquals(4, config.method)
        assertEquals(WebPImageHint.PHOTO, config.imageHint)
        assertEquals(1, config.autofilter)
        assertEquals(0, config.exact)
    }

    @Test
    fun `fromMap ignores unsupported optional values`() {
        val config = WebPConfig.fromMap(
            mapOf(
                "quality" to "not a number",
                "imageHint" to "unknown",
            ),
        )

        assertNull(config.quality)
        assertNull(config.imageHint)
    }
}
