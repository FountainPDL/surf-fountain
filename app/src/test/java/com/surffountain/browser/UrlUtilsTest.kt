package com.surffountain.browser

import com.surffountain.browser.utils.UrlUtils
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class UrlUtilsTest {

    private val ddg = "https://duckduckgo.com/?q=%s"

    @Test
    fun bareDomainGetsHttpsPrefix() {
        assertEquals("https://example.com", UrlUtils.resolveInput("example.com", ddg))
    }

    @Test
    fun alreadySchemedUrlIsUntouched() {
        assertEquals("http://example.com", UrlUtils.resolveInput("http://example.com", ddg))
    }

    @Test
    fun plainTextBecomesASearchQuery() {
        assertEquals(
            "https://duckduckgo.com/?q=best+pour+over+kettle",
            UrlUtils.resolveInput("best pour over kettle", ddg)
        )
    }

    @Test
    fun multiWordQueryWithPunctuationIsEncoded() {
        val result = UrlUtils.resolveInput("what is 2+2?", ddg)
        assertTrue(result.startsWith("https://duckduckgo.com/?q="))
    }

    @Test
    fun localhostWithPortIsTreatedAsAnAddress() {
        assertEquals("https://localhost:8080", UrlUtils.resolveInput("localhost:8080", ddg))
    }

    @Test
    fun blankInputResolvesToEmptyString() {
        assertEquals("", UrlUtils.resolveInput("   ", ddg))
    }
}
