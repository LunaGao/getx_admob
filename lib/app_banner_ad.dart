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
  AdmobUnitId? _lastRequestedAdUnit;
  int? _lastRequestedWidth;

  @override
  void didUpdateWidget(covariant AppBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adBannerValue != widget.adBannerValue) {
      _lastRequestedAdUnit = null;
      _lastRequestedWidth = null;
    }
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
          final bannerAd = adService.isOnDemandBannerLoadingEnabled
              ? adService.bannerAdFor(widget.adBannerValue, width)
              : adService.bannerAds[widget.adBannerValue];
          if (!isLoaded || bannerAd == null) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            width: bannerAd.size.width.toDouble(),
            height: bannerAd.size.height.toDouble(),
            child: AdWidget(ad: bannerAd),
          );
        });
      },
    );
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
      adService.ensureBannerLoaded(adUnit, width);
    });
  }
}
