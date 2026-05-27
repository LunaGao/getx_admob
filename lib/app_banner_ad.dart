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

class _AppBannerAdState extends State<AppBannerAd> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Start observing
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Get.find<AdmobService>().showAppOpenAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final adService = Get.find<AdmobService>();

    return Obx(
      () => adService.loadedAds[widget.adBannerValue] ?? false
          ? SizedBox(
              width: adService.bannerAds[widget.adBannerValue]!.size.width
                  .toDouble(),
              height: adService.bannerAds[widget.adBannerValue]!.size.height
                  .toDouble(),
              child: AdWidget(ad: adService.bannerAds[widget.adBannerValue]!),
            )
          : const SizedBox(),
    );
  }
}
