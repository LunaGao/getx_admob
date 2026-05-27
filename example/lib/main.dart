import 'package:example/app_ad_units.dart';
import 'package:example/my_app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import getx admob
import 'package:getx_admob/getx_admob.dart';

void main() {
  // ensure initialized
  WidgetsFlutterBinding.ensureInitialized();
  // init admob service
  Get.put(() => AdmobService().init(AppAdUnits.adUnits));

  runApp(const MyApp());
}
