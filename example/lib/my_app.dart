import 'package:example/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_admob/getx_admob.dart';

import 'home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Admob Example',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: HomePage(),
      routes: {'/detail': (context) => const DetailPage()},
      builder: (context, child) {
        return AdaptiveAdLoader(child: child);
      },
    );
  }
}
