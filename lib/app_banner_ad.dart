import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_admob/admob_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_unit_id.dart';

class AppBannerAd extends StatefulWidget {
  const AppBannerAd(this.adBannerValue, {super.key});
  final AdmobUnitId adBannerValue;

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  final Object _bannerOwner = Object();
  AdmobUnitId? _lastRequestedAdUnit;
  int? _lastRequestedWidth;
  bool _isMountRetryScheduled = false;

  @override
  void didUpdateWidget(covariant AppBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adBannerValue != widget.adBannerValue) {
      _lastRequestedAdUnit = null;
      _lastRequestedWidth = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AdmobService>()) {
        Get.find<AdmobService>().releaseBannerAds(_bannerOwner);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = Get.find<AdmobService>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final width = availableWidth.truncate();
        if (width <= 0) {
          return const SizedBox.shrink();
        }
        if (adService.isOnDemandBannerLoadingEnabled) {
          _requestBanner(adService, width);
        }
        return Obx(() {
          final isLoaded = adService.loadedAds[widget.adBannerValue] ?? false;
          final isOnDemand = adService.isOnDemandBannerLoadingEnabled;
          final bannerAd = isOnDemand
              ? adService.bannerAdFor(
                  widget.adBannerValue,
                  width,
                  owner: _bannerOwner,
                )
              : adService.bannerAds[widget.adBannerValue];
          if (!isLoaded || bannerAd == null) {
            return const SizedBox.shrink();
          }
          final isMounted = !isOnDemand && bannerAd.isMounted;
          if (isMounted) {
            _retryMountedAdAfterFrame();
          }
          return SizedBox(
            width: bannerAd.size.width.toDouble(),
            height: bannerAd.size.height.toDouble(),
            child: isMounted ? null : AdWidget(ad: bannerAd),
          );
        });
      },
    );
  }

  void _retryMountedAdAfterFrame() {
    if (_isMountRetryScheduled) {
      return;
    }
    _isMountRetryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isMountRetryScheduled = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _requestBanner(AdmobService adService, int width) {
    if (_lastRequestedAdUnit == widget.adBannerValue &&
        _lastRequestedWidth == width) {
      return;
    }
    _lastRequestedAdUnit = widget.adBannerValue;
    _lastRequestedWidth = width;
    final adUnit = widget.adBannerValue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          adUnit != widget.adBannerValue ||
          !Get.isRegistered<AdmobService>()) {
        return;
      }
      adService.ensureBannerLoaded(adUnit, width, owner: _bannerOwner);
    });
  }
}
