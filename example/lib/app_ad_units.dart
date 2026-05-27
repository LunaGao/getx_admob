import 'package:getx_admob/getx_admob.dart';

class AppAdUnits {
  static List<AdmobUnitId> adUnits = [
    AppAdUnits.homeBanner,
    AppAdUnits.detailBanner,
  ];

  static AdmobUnitId homeBanner = AdmobUnitId(
    androidUnitId: 'ca-app-pub-3940256099942544/9214589741',
    iosUnitId: 'ca-app-pub-3940256099942544/2435281174',
  );

  static AdmobUnitId detailBanner = AdmobUnitId(
    androidUnitId: 'ca-app-pub-3940256099942544/9214589741',
    iosUnitId: 'ca-app-pub-3940256099942544/2435281174',
  );
}
