import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  bool _initialized = false;
  
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      // Preload the first interstitial ad immediately
      loadInterstitial();
    } catch (e) {
      // Fail silently to prevent launch issues in offline or non-GMS environments
    }
  }

  // Preload an interstitial ad in the background
  void loadInterstitial() {
    if (!_initialized || _isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Standard Google test interstitial ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (err) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  // Show the preloaded interstitial ad if ready, then execute callback to transition
  void showInterstitial(VoidCallback onAdDismissed) {
    if (!_initialized || _interstitialAd == null) {
      // If ad is not ready, immediately continue to the game screen without interrupting
      onAdDismissed();
      loadInterstitial(); // Try preloading again
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed(); // Go to game screen
        loadInterstitial(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed(); // Go to game screen
        loadInterstitial(); // Preload next ad
      },
    );

    _interstitialAd!.show();
  }
}
