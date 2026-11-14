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
        reserveSpace()
        container.post {
            if (adView != null) return@post
            createAndLoad()
        }
    }

    private fun reserveSpace() {
        val params = container.layoutParams
        params.height = anchoredAdaptiveSize().getHeightInPixels(activity)
        container.layoutParams = params
        if (container.visibility != View.VISIBLE) {
            container.visibility = View.INVISIBLE
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
                    container.visibility = View.INVISIBLE
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
        container.visibility = View.INVISIBLE
    }

    private fun applyVisibility() {
        container.visibility = if (loaded && homeVisible) View.VISIBLE else View.INVISIBLE
    }

    private fun anchoredAdaptiveSize(): AdSize {
        val metrics = activity.resources.displayMetrics
        val parentWidth = (container.parent as? View)?.width ?: 0
        val widthPx = if (parentWidth > 0) {
            parentWidth
        } else {
            val horizontalInset = (40 * metrics.density).toInt()
            (metrics.widthPixels - horizontalInset).coerceAtLeast(1)
        }
        val adWidth = (widthPx / metrics.density).toInt().coerceAtLeast(1)
        return AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(activity, adWidth)
    }

    private companion object {
        const val TAG = "HomeBannerAd"
    }
}
