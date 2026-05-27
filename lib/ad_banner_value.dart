import 'package:get/get.dart';

enum AdBannerValue {
  loginBanner(
    // <---- 对应banner的名字
    androidUnitId: 'XXX',
    iosUnitId: 'XXX',
  ),

  ///...
  mainBanner(
    // <---- 对应banner的名字
    androidUnitId: 'XXX',
    iosUnitId: 'XXX',
  );

  const AdBannerValue({required this.androidUnitId, required this.iosUnitId});

  final String androidUnitId;
  final String iosUnitId;

  String get productionUnitId {
    if (GetPlatform.isIOS) {
      return iosUnitId;
    }
    if (GetPlatform.isAndroid) {
      return androidUnitId;
    }
    return '';
  }
}
