import 'package:example/my_app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// import getx admob
import 'package:getx_admob/getx_admob.dart';

void main() {
  // init admob service
  Get.put(() => AdmobService().init());

  runApp(const MyApp());
}
