import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_unit_id.dart';
import 'ad_build_config.dart';

class AdmobService extends GetxService {
  AdmobService({AdBuildConfig? buildConfig})
    : _buildConfig = buildConfig ?? const AdBuildConfig.fromEnvironment();

  final AdBuildConfig _buildConfig;
  bool get enableAd => _buildConfig.enableAd;
  bool get debugAd => _buildConfig.debugAd;
  var loadedAds = <AdmobUnitId, bool>{}.obs;
  var bannerAds = <AdmobUnitId, BannerAd>{}.obs;
  bool _hasLoadedBannerAds = false;
  bool _isLoadingAppOpenAd = false;
  int? _bannerWidth;

  // ===== 开屏广告 start =====
  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = const Duration(hours: 4);
  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;

  /// Keep track of load time so we don't show an expired ad.
  DateTime? _appOpenLoadTime;

  /// Whether an ad is available to be shown.
  bool get isAppOpenAdAvailable {
    return _appOpenAd != null;
  }
  // ===== 开屏广告 end =====

  Future<AdmobService> init(List<AdmobUnitId> adUnitIds) async {
    loadedAds.value = {for (final banner in adUnitIds) banner: false};
    if (!enableAd) {
      return this;
    }
    await MobileAds.instance.initialize();
    _loadAppOpenAd();
    return this;
  }

  String getAppOpenAdUnitId() {
    if (debugAd) {
      if (GetPlatform.isAndroid) {
        return 'ANDROID_DEBUG_AD_UNIT_ID';
      } else {
        return 'IOS_DEBUG_AD_UNIT_ID';
      }
    }
    // 如果是正式环境
    if (GetPlatform.isAndroid) {
      // Android 正式环境
      return 'Android的开屏广告ID';
    }
    if (GetPlatform.isIOS) {
      // iOS 正式环境
      return 'iOS的开屏广告ID';
    }

    return '';
  }

  String getAdUnitId(AdmobUnitId adValue) {
    if (debugAd) {
      if (GetPlatform.isAndroid) {
        return 'ANDROID_DEBUG_AD_UNIT_ID';
      } else {
        return 'IOS_DEBUG_AD_UNIT_ID';
      }
    }
    return adValue.productionUnitId;
  }

  Future<void> loadAllAds(int width) async {
    if (!enableAd) {
      return;
    }
    if (width <= 0) {
      return;
    }
    if (_hasLoadedBannerAds && _bannerWidth == width) {
      return;
    }
    if (_bannerWidth != null && _bannerWidth != width) {
      _disposeBannerAds();
    }
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size != null) {
      _bannerWidth = width;
      _hasLoadedBannerAds = true;
      // 循环载入所有Banner广告
      for (AdmobUnitId adBanner in loadedAds.keys) {
        _loadAd(adBanner, size);
      }
    }
  }

  void _loadAppOpenAd() {
    if (!enableAd || _isLoadingAppOpenAd || _appOpenAd != null) {
      return;
    }
    _isLoadingAppOpenAd = true;
    // 循环开屏广告
    AppOpenAd.load(
      adUnitId: getAppOpenAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded');
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
          _isLoadingAppOpenAd = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
          _isLoadingAppOpenAd = false;
        },
      ),
    );
  }

  void _loadAd(AdmobUnitId adUnitId, AnchoredAdaptiveBannerAdSize size) async {
    bannerAds.remove(adUnitId)?.dispose();
    loadedAds[adUnitId] = false;
    bannerAds[adUnitId] = BannerAd(
      adUnitId: getAdUnitId(adUnitId),
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Ad was loaded.");
          bannerAds[adUnitId] = ad as BannerAd;
          loadedAds[adUnitId] = true;
          bannerAds.refresh();
          loadedAds.refresh();
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint("Ad failed to load with error: $err");
          loadedAds[adUnitId] = false;
          bannerAds.remove(adUnitId);
          bannerAds.refresh();
          loadedAds.refresh();
          ad.dispose();
        },
      ),
    );

    bannerAds[adUnitId]?.load();
  }

  // ===== 开屏广告 start =====
  /// Shows the ad, if one exists and is not already being shown.
  ///
  /// If the previously cached ad has expired, this just loads and caches a
  /// new ad.
  void showAppOpenAdIfAvailable() {
    if (!enableAd) {
      return;
    }
    if (!isAppOpenAdAvailable) {
      debugPrint('Tried to show ad before available.');
      _loadAppOpenAd();
      return;
    }
    if (_isShowingAppOpenAd) {
      debugPrint('Tried to show ad while already showing an ad.');
      return;
    }
    if (DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      debugPrint('Maximum cache duration exceeded. Loading another ad.');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      _loadAppOpenAd();
      return;
    }
    // Set the fullScreenContentCallback and show the ad.
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpenAd = true;
        debugPrint('$ad onAdShowedFullScreenContent');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('$ad onAdDismissedFullScreenContent');
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }

  @override
  void onClose() {
    _disposeBannerAds();
    _appOpenAd?.dispose();
    _appOpenAd = null;
    super.onClose();
  }

  void _disposeBannerAds() {
    for (final ad in bannerAds.values) {
      ad.dispose();
    }
    bannerAds.clear();
    for (final adBanner in loadedAds.keys) {
      loadedAds[adBanner] = false;
    }
    bannerAds.refresh();
    loadedAds.refresh();
    _hasLoadedBannerAds = false;
    _bannerWidth = null;
  }
}
