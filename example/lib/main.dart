import 'package:example/app_ad_units.dart';
import 'package:example/my_app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import getx admob
import 'package:getx_admob/getx_admob.dart';

void main() async {
  // ensure initialized
  WidgetsFlutterBinding.ensureInitialized();
  // init admob service
  await Get.putAsync(
    () => AdmobService().init(
      adUnitIds: AppAdUnits.adUnits,
      // using for production
      appOpenAdUnitId: AdmobUnitId(
        androidUnitId: 'ca-app-pub-3940256099942544/9257395921',
        iosUnitId: 'ca-app-pub-3940256099942544/5575463023',
      ),
    ),
  );

  runApp(const MyApp());
}
