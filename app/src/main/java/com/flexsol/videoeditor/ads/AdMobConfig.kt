package com.flexsol.videoeditor.ads

object AdMobConfig {
    const val APPLICATION_ID = "ca-app-pub-7565515230645412~2800748029"

    /**
     * Banner ad unit from AdMob (uses a slash: ca-app-pub-xxxxxxxx/yyyyyyyy).
     * The id in [APPLICATION_ID] is the app id and cannot be requested as a banner.
     * Leave this blank to show Google's test banner until the real unit is pasted here.
     */
    const val HOME_BANNER_AD_UNIT_ID = ""

//    private const val TEST_BANNER_AD_UNIT_ID = "ca-app-pub-3940256099942544/6300978111" // test ad unit
    private const val TEST_BANNER_AD_UNIT_ID = "ca-app-pub-7565515230645412/8802370976"

    /** OnePlus DN2103, from the Ads log: setTestDeviceIds. */
    const val TEST_DEVICE_ID = "EF8020644ADF8CC95168370FBFB4EA9A"

    fun homeBannerAdUnitId(): String = HOME_BANNER_AD_UNIT_ID.ifBlank { TEST_BANNER_AD_UNIT_ID }
}
