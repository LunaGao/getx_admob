import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_build_config.dart';
import 'admob_diagnostics.dart';
import 'admob_unit_id.dart';

class AdmobService extends GetxService {
  final AdBuildConfig _buildConfig = const AdBuildConfig.fromEnvironment();
  bool get enableAd => _buildConfig.enableAd;
  bool get debugAd => _buildConfig.debugAd;
  var loadedAds = <AdmobUnitId, bool>{}.obs;
  var bannerAds = <AdmobUnitId, BannerAd>{}.obs;
  final _bannerEntries = <_BannerCacheKey, _BannerAdEntry>{};
  bool _hasLoadedBannerAds = false;
  bool _isLoadingAppOpenAd = false;
  bool _isOnDemandBannerLoadingEnabled = false;
  bool _isClosed = false;
  int? _bannerWidth;
  AdmobBannerSizePolicy _bannerSizePolicy = AdmobBannerSizePolicy.largeAdaptive;
  AdmobDiagnosticCallback? _diagnosticCallback;

  static const _maxBannerRetries = 3;

  bool get isOnDemandBannerLoadingEnabled => _isOnDemandBannerLoadingEnabled;

  AdmobBannerSizePolicy get bannerSizePolicy => _bannerSizePolicy;

  void setOnDemandBannerLoading(bool enabled) {
    _isOnDemandBannerLoadingEnabled = enabled;
  }

  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = const Duration(hours: 4);
  late AdmobUnitId appOpenAdUnitId;
  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpenAd = false;

  /// Keep track of load time so we don't show an expired ad.
  DateTime? _appOpenLoadTime;
  DateTime? _appOpenLoadStartedAt;
  DateTime? _appOpenShowRequestedAt;
  DateTime? _appOpenShownAt;

  /// Whether an ad is available to be shown.
  bool get isAppOpenAdAvailable {
    return _appOpenAd != null;
  }

  bool get isAppOpenAdLoading => _isLoadingAppOpenAd;
  bool get isAppOpenAdShowing => _isShowingAppOpenAd;
  DateTime? get appOpenLoadTime => _appOpenLoadTime;

  Future<AdmobService> init({
    required List<AdmobUnitId> adUnitIds,
    required AdmobUnitId appOpenAdUnitId,
    AdmobBannerSizePolicy bannerSizePolicy =
        AdmobBannerSizePolicy.largeAdaptive,
    AdmobDiagnosticCallback? onDiagnostic,
  }) async {
    if (!GetPlatform.isAndroid && !GetPlatform.isIOS) {
      // 非Android和IOS平台，不初始化广告
      return this;
    }
    this.appOpenAdUnitId = appOpenAdUnitId;
    _bannerSizePolicy = bannerSizePolicy;
    _diagnosticCallback = onDiagnostic;
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
      // https://developers.google.com/admob/flutter/app-open
      // values for debug
      if (GetPlatform.isAndroid) {
        // debug value
        return 'ca-app-pub-3940256099942544/9257395921';
      } else {
        // debug value
        return 'ca-app-pub-3940256099942544/5575463023';
      }
    }
    return appOpenAdUnitId.productionUnitId;
  }

  String getAdUnitId(AdmobUnitId adValue) {
    if (debugAd) {
      // https://developers.google.com/admob/flutter/banner
      // values for debug
      if (GetPlatform.isAndroid) {
        // debug value
        return 'ca-app-pub-3940256099942544/9214589741';
      } else {
        // debug value
        return 'ca-app-pub-3940256099942544/2435281174';
      }
    }
    return adValue.productionUnitId;
  }

  Future<void> loadAllAds(int width) async {
    if (!_canLoadBanner(width)) {
      return;
    }
    if (_hasLoadedBannerAds && _bannerWidth == width) {
      return;
    }
    _bannerWidth = width;
    _hasLoadedBannerAds = true;
    for (final adBanner in loadedAds.keys) {
      unawaited(ensureBannerLoaded(adBanner, width));
    }
  }

  Future<void> ensureBannerLoaded(AdmobUnitId adUnitId, int width) async {
    if (!_canLoadBanner(width)) {
      return;
    }
    if (!loadedAds.containsKey(adUnitId)) {
      debugPrint(
        'Banner ad unit was not registered: ${adUnitId.productionUnitId}',
      );
      return;
    }
    final key = _BannerCacheKey(adUnitId, width);
    var entry = _bannerEntries[key];
    if (entry != null) {
      if (entry.status == _BannerLoadStatus.loading ||
          entry.status == _BannerLoadStatus.waitingForRetry ||
          entry.status == _BannerLoadStatus.loaded) {
        return;
      }
      entry.retryCount = 0;
    } else {
      entry = _BannerAdEntry(key);
      _bannerEntries[key] = entry;
    }
    await _loadBannerEntry(entry);
  }

  BannerAd? bannerAdFor(AdmobUnitId adUnitId, int width) {
    final entry = _bannerEntries[_BannerCacheKey(adUnitId, width)];
    if (entry?.status != _BannerLoadStatus.loaded) {
      return null;
    }
    return entry!.ad;
  }

  bool _canLoadBanner(int width) {
    return enableAd &&
        !_isClosed &&
        width > 0 &&
        (GetPlatform.isAndroid || GetPlatform.isIOS);
  }

  Future<void> _loadBannerEntry(_BannerAdEntry entry) async {
    final key = entry.key;
    entry.retryTimer?.cancel();
    entry.retryTimer = null;
    entry.ad?.dispose();
    entry.ad = null;
    entry.status = _BannerLoadStatus.loading;
    final generation = ++entry.generation;

    late final AnchoredAdaptiveBannerAdSize? size;
    try {
      switch (_bannerSizePolicy) {
        case AdmobBannerSizePolicy.standardAdaptive:
          // ignore: deprecated_member_use
          size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            key.width,
          );
        case AdmobBannerSizePolicy.largeAdaptive:
          size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(key.width);
      }
    } catch (error) {
      _handleBannerLoadFailure(
        key,
        entry,
        generation,
        errorMessage: error.toString(),
      );
      return;
    }

    if (!_isCurrentBannerEntry(key, entry, generation)) {
      return;
    }
    if (size == null) {
      _handleBannerLoadFailure(
        key,
        entry,
        generation,
        errorMessage:
            'No adaptive banner size is available for ${key.width}px.',
      );
      return;
    }

    final bannerAd = BannerAd(
      adUnitId: getAdUnitId(key.adUnitId),
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!_isCurrentBannerEntry(key, entry, generation)) {
            ad.dispose();
            return;
          }
          entry.ad = ad as BannerAd;
          entry.status = _BannerLoadStatus.loaded;
          entry.retryCount = 0;
          debugPrint('Banner ad loaded: ${key.adUnitId.productionUnitId}');
          _syncLegacyBannerAds(key.adUnitId);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!_isCurrentBannerEntry(key, entry, generation)) {
            return;
          }
          entry.ad = null;
          _handleBannerLoadFailure(
            key,
            entry,
            generation,
            errorCode: error.code,
            errorDomain: error.domain,
            errorMessage: error.message,
          );
        },
      ),
    );
    entry.ad = bannerAd;
    unawaited(bannerAd.load());
  }

  void _handleBannerLoadFailure(
    _BannerCacheKey key,
    _BannerAdEntry entry,
    int generation, {
    int? errorCode,
    String? errorDomain,
    required String errorMessage,
  }) {
    if (!_isCurrentBannerEntry(key, entry, generation)) {
      return;
    }
    entry.status = _BannerLoadStatus.failed;
    debugPrint(
      'Banner ad failed: ${key.adUnitId.productionUnitId}, '
      'code=$errorCode, domain=$errorDomain, message=$errorMessage',
    );
    _syncLegacyBannerAds(key.adUnitId);

    if (entry.retryCount >= _maxBannerRetries) {
      debugPrint(
        'Banner ad retry limit reached: ${key.adUnitId.productionUnitId}',
      );
      return;
    }

    entry.retryCount += 1;
    final delaySeconds = 2 << (entry.retryCount - 1);
    entry.status = _BannerLoadStatus.waitingForRetry;
    debugPrint(
      'Banner ad retry ${entry.retryCount}/$_maxBannerRetries '
      'in ${delaySeconds}s: ${key.adUnitId.productionUnitId}',
    );
    entry.retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isCurrentBannerEntry(key, entry, generation) ||
          entry.status != _BannerLoadStatus.waitingForRetry) {
        return;
      }
      entry.retryTimer = null;
      unawaited(_loadBannerEntry(entry));
    });
  }

  bool _isCurrentBannerEntry(
    _BannerCacheKey key,
    _BannerAdEntry entry,
    int generation,
  ) {
    return !_isClosed &&
        identical(_bannerEntries[key], entry) &&
        entry.generation == generation;
  }

  void _syncLegacyBannerAds(AdmobUnitId adUnitId) {
    BannerAd? loadedAd;
    for (final entry in _bannerEntries.values) {
      if (entry.key.adUnitId == adUnitId &&
          entry.status == _BannerLoadStatus.loaded) {
        loadedAd = entry.ad;
      }
    }
    if (loadedAd == null) {
      bannerAds.remove(adUnitId);
      loadedAds[adUnitId] = false;
    } else {
      bannerAds[adUnitId] = loadedAd;
      loadedAds[adUnitId] = true;
    }
    bannerAds.refresh();
    loadedAds.refresh();
  }

  void _loadAppOpenAd() {
    if (!enableAd || _isClosed || _isLoadingAppOpenAd || _appOpenAd != null) {
      return;
    }
    _isLoadingAppOpenAd = true;
    _appOpenLoadStartedAt = DateTime.now();
    _emitAppOpenDiagnostic(AdmobDiagnosticType.appOpenLoadStarted);
    AppOpenAd.load(
      adUnitId: getAppOpenAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAppOpenAd = false;
          if (_isClosed) {
            ad.dispose();
            return;
          }
          final loadStartedAt = _appOpenLoadStartedAt;
          _appOpenLoadStartedAt = null;
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
          _emitAppOpenDiagnostic(
            AdmobDiagnosticType.appOpenLoaded,
            duration: loadStartedAt == null
                ? null
                : DateTime.now().difference(loadStartedAt),
          );
        },
        onAdFailedToLoad: (error) {
          _isLoadingAppOpenAd = false;
          if (_isClosed) {
            return;
          }
          final loadStartedAt = _appOpenLoadStartedAt;
          _appOpenLoadStartedAt = null;
          _emitAppOpenDiagnostic(
            AdmobDiagnosticType.appOpenLoadFailed,
            duration: loadStartedAt == null
                ? null
                : DateTime.now().difference(loadStartedAt),
            error: error,
          );
        },
      ),
    );
  }

  /// Shows the ad, if one exists and is not already being shown.
  ///
  /// If the previously cached ad has expired, this just loads and caches a
  /// new ad.
  void showAppOpenAdIfAvailable() {
    if (!enableAd ||
        _isClosed ||
        (!GetPlatform.isAndroid && !GetPlatform.isIOS)) {
      return;
    }
    if (!isAppOpenAdAvailable) {
      _emitAppOpenDiagnostic(AdmobDiagnosticType.appOpenUnavailable);
      _loadAppOpenAd();
      return;
    }
    if (_isShowingAppOpenAd) {
      _emitAppOpenDiagnostic(AdmobDiagnosticType.appOpenAlreadyShowing);
      return;
    }
    if (DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      _emitAppOpenDiagnostic(AdmobDiagnosticType.appOpenExpired);
      _appOpenAd!.dispose();
      _appOpenAd = null;
      _appOpenLoadTime = null;
      _loadAppOpenAd();
      return;
    }
    final ad = _appOpenAd!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        if (_isClosed) {
          return;
        }
        _isShowingAppOpenAd = true;
        _appOpenShownAt = DateTime.now();
        final showRequestedAt = _appOpenShowRequestedAt;
        _emitAppOpenDiagnostic(
          AdmobDiagnosticType.appOpenShown,
          duration: showRequestedAt == null
              ? null
              : DateTime.now().difference(showRequestedAt),
        );
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpenAd = false;
        final showRequestedAt = _appOpenShowRequestedAt;
        _appOpenShowRequestedAt = null;
        _appOpenShownAt = null;
        ad.dispose();
        if (identical(_appOpenAd, ad)) {
          _appOpenAd = null;
          _appOpenLoadTime = null;
        }
        if (!_isClosed) {
          _emitAppOpenDiagnostic(
            AdmobDiagnosticType.appOpenShowFailed,
            duration: showRequestedAt == null
                ? null
                : DateTime.now().difference(showRequestedAt),
            error: error,
          );
          _loadAppOpenAd();
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        final shownAt = _appOpenShownAt;
        _appOpenShowRequestedAt = null;
        _appOpenShownAt = null;
        ad.dispose();
        if (identical(_appOpenAd, ad)) {
          _appOpenAd = null;
          _appOpenLoadTime = null;
        }
        if (!_isClosed) {
          _emitAppOpenDiagnostic(
            AdmobDiagnosticType.appOpenDismissed,
            duration: shownAt == null
                ? null
                : DateTime.now().difference(shownAt),
          );
          _loadAppOpenAd();
        }
      },
    );
    _appOpenShowRequestedAt = DateTime.now();
    _emitAppOpenDiagnostic(AdmobDiagnosticType.appOpenShowRequested);
    ad.show();
  }

  void _emitAppOpenDiagnostic(
    AdmobDiagnosticType type, {
    Duration? duration,
    AdError? error,
  }) {
    final event = AdmobDiagnosticEvent(
      type: type,
      timestamp: DateTime.now(),
      adUnitId: appOpenAdUnitId.productionUnitId,
      duration: duration,
      errorCode: error?.code,
      errorDomain: error?.domain,
      errorMessage: error?.message,
    );
    debugPrint(event.toString());
    try {
      _diagnosticCallback?.call(event);
    } catch (callbackError) {
      debugPrint('AdMob diagnostic callback failed: $callbackError');
    }
  }

  @override
  void onClose() {
    _isClosed = true;
    _disposeBannerAds();
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _appOpenLoadTime = null;
    _appOpenLoadStartedAt = null;
    _appOpenShowRequestedAt = null;
    _appOpenShownAt = null;
    _isLoadingAppOpenAd = false;
    _isShowingAppOpenAd = false;
    super.onClose();
  }

  void _disposeBannerAds() {
    for (final entry in _bannerEntries.values) {
      entry.generation++;
      entry.retryTimer?.cancel();
      entry.retryTimer = null;
      entry.ad?.dispose();
      entry.ad = null;
      entry.status = _BannerLoadStatus.idle;
    }
    _bannerEntries.clear();
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

class _BannerCacheKey {
  const _BannerCacheKey(this.adUnitId, this.width);

  final AdmobUnitId adUnitId;
  final int width;

  @override
  bool operator ==(Object other) {
    return other is _BannerCacheKey &&
        other.adUnitId == adUnitId &&
        other.width == width;
  }

  @override
  int get hashCode => Object.hash(adUnitId, width);
}

enum _BannerLoadStatus { idle, loading, waitingForRetry, loaded, failed }

class _BannerAdEntry {
  _BannerAdEntry(this.key);

  final _BannerCacheKey key;
  BannerAd? ad;
  _BannerLoadStatus status = _BannerLoadStatus.idle;
  int generation = 0;
  int retryCount = 0;
  Timer? retryTimer;
}
