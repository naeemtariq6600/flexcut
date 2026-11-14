package com.flexsol.videoeditor.ads

import android.app.Activity
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import com.google.android.gms.ads.AdListener
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import com.google.android.gms.ads.LoadAdError

/**
 * Adaptive banner placed in the home-tab content, between the new-project card and
 * the saved-projects list. It is not docked to the navigation bar.
 */
class HomeBannerAd(
    private val activity: Activity,
    private val container: FrameLayout,
) {
    private var adView: AdView? = null
    private var loaded = false
    private var homeVisible = true
    private var loadStarted = false

    fun load() {
        if (loadStarted) return
        loadStarted = true
        container.post {
            if (adView != null) return@post
            createAndLoad()
        }
    }

    private fun createAndLoad() {
        val banner = AdView(activity).apply {
            adUnitId = AdMobConfig.homeBannerAdUnitId()
            setAdSize(anchoredAdaptiveSize())
            adListener = object : AdListener() {
                override fun onAdLoaded() {
                    loaded = true
                    applyVisibility()
                }

                override fun onAdFailedToLoad(error: LoadAdError) {
                    Log.w(TAG, "Home banner failed to load: ${error.code} ${error.message}")
                    loaded = false
                    container.visibility = View.GONE
                }
            }
        }

        container.removeAllViews()
        container.addView(
            banner,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
            ),
        )
        adView = banner
        banner.loadAd(AdRequest.Builder().build())
    }

    fun setHomeVisible(visible: Boolean) {
        homeVisible = visible
        if (visible) {
            adView?.resume()
        } else {
            adView?.pause()
        }
        applyVisibility()
    }

    fun pause() {
        adView?.pause()
    }

    fun resume() {
        if (homeVisible) adView?.resume()
    }

    fun destroy() {
        adView?.destroy()
        adView = null
        loaded = false
        container.removeAllViews()
        container.visibility = View.GONE
    }

    private fun applyVisibility() {
        val show = loaded && homeVisible
        container.visibility = if (show) View.VISIBLE else View.GONE
    }

    private fun anchoredAdaptiveSize(): AdSize {
        val metrics = activity.resources.displayMetrics
        val parent = container.parent as? View
        val widthPx = parent?.width?.takeIf { it > 0 }
            ?: (metrics.widthPixels - parent.horizontalPadding()).coerceAtLeast(1)
        val adWidth = (widthPx / metrics.density).toInt().coerceAtLeast(1)
        return AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, adWidth)
    }

    private fun View?.horizontalPadding(): Int {
        if (this == null) return 0
        return paddingLeft + paddingRight
    }

    private companion object {
        const val TAG = "HomeBannerAd"
    }
}
