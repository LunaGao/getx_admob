import 'package:example/app_ad_units.dart';
import 'package:flutter/material.dart';
import 'package:getx_admob/getx_admob.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Admob Example"),
      ),
      body: Column(
        children: [
          AppBannerAd(AppAdUnits.detailBanner),
          const Text('this is detail show ad'),
        ],
      ),
    );
  }
}
