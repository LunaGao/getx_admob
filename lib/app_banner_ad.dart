import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_admob/admob_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_banner_value.dart';

class AppBannerAd extends StatelessWidget {
  const AppBannerAd(this.adBannerValue, {super.key});

  final AdBannerValue adBannerValue;

  @override
  Widget build(BuildContext context) {
    final adService = Get.find<AdmobService>();

    return Obx(
      () => adService.loadedAds[adBannerValue] ?? false
          ? SizedBox(
              width: adService.bannerAds[adBannerValue]!.size.width.toDouble(),
              height: adService.bannerAds[adBannerValue]!.size.height
                  .toDouble(),
              child: AdWidget(ad: adService.bannerAds[adBannerValue]!),
            )
          : const SizedBox(),
    );
  }
}
