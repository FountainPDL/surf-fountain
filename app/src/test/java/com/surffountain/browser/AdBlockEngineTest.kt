package com.surffountain.browser

import com.surffountain.browser.privacy.AdBlockEngine
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AdBlockEngineTest {

    @Test
    fun exactDomainMatchIsBlocked() {
        assertTrue(AdBlockEngine.isBlocked("doubleclick.net", enabled = true))
    }

    @Test
    fun subdomainOfBlockedDomainIsBlocked() {
        assertTrue(AdBlockEngine.isBlocked("ad.doubleclick.net", enabled = true))
    }

    @Test
    fun unrelatedDomainIsNotBlocked() {
        assertFalse(AdBlockEngine.isBlocked("example.com", enabled = true))
    }

    @Test
    fun similarButUnrelatedDomainIsNotFalselyBlocked() {
        // must not match on a substring — "notdoubleclick.net" is not
        // doubleclick.net nor a subdomain of it
        assertFalse(AdBlockEngine.isBlocked("notdoubleclick.net", enabled = true))
    }

    @Test
    fun disabledShieldsBlocksNothing() {
        assertFalse(AdBlockEngine.isBlocked("doubleclick.net", enabled = false))
    }

    @Test
    fun allowlistedDomainIsNotBlocked() {
        assertFalse(
            AdBlockEngine.isBlocked("doubleclick.net", enabled = true, allowlist = setOf("doubleclick.net"))
        )
    }

    @Test
    fun allowlistCoversSubdomainsToo() {
        assertFalse(
            AdBlockEngine.isBlocked("ads.doubleclick.net", enabled = true, allowlist = setOf("doubleclick.net"))
        )
    }

    @Test
    fun blankOrNullHostIsNotBlocked() {
        assertFalse(AdBlockEngine.isBlocked("", enabled = true))
        assertFalse(AdBlockEngine.isBlocked(null, enabled = true))
    }

    @Test
    fun matchingIsCaseInsensitive() {
        assertTrue(AdBlockEngine.isBlocked("Ad.DoubleClick.NET", enabled = true))
    }
}
