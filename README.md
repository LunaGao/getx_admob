![getx_admob](https://socialify.git.ci/LunaGao/getx_admob/image?custom_language=Flutter&description=1&font=Raleway&forks=1&issues=1&language=1&name=1&owner=1&pattern=Signal&pulls=1&stargazers=1&theme=Auto)


[![Bless](https://img.shields.io/badge/bless-God-brightgreen)](https://lunagao.github.io/BlessYourCodeTag/)
![Pub Version](https://img.shields.io/pub/v/getx_admob)

Easy to implement AdMob using GetX in Flutter. Only support __Android__ and __iOS__.

> __Note__: **0.1.0 version and above** are using for **Flutter 3.44.0 and above** (iOS package is using Swift Package). If you are using Flutter 3.41.9 and below (iOS using Pod), please use 0.0.2 version.

## Features

* banner ad.
* open app ad.

| Feature | Screenshot | Feature | Screenshot |
| --- | --- | --- | --- |
| open app ad | ![open app ad](https://raw.githubusercontent.com/LunaGao/getx_admob/main/img/img1.png) | banner ad | ![banner ad](https://raw.githubusercontent.com/LunaGao/getx_admob/main/img/img2.png) |

## Getting started

Steps: 
* Import this package.
* Add admob application ID
  * iOS Info.plist
  * Android AndroidManifest.xml
* Add app_ad_units.dart file.
* Modify main.dart file.
* Modify my_app.dart file.
* Modify page, add banner ad.


## Usage

According to the [official documentation](https://developers.google.com/admob/flutter/quick-start),

Configure your AdMob application ID.
* Add iOS Info.plist.
* Add AndroidManifest.xml.

#### ios/Runner/Info.plist
```xml
<plist version="1.0">
<dict>
	<!-- ... -->
	<key>GADApplicationIdentifier</key>
	<string>ca-app-pub-3940256099942544~1458002511</string>
</dict>
</plist>
```

#### android/app/src/main/AndroidManifest.xml
```xml
<manifest>
    <application>
        <!-- ... -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-3940256099942544~3347511713"/>
    </application>
</manifest>
```


## Code example

Add app_ad_units.dart file
```dart
import 'package:getx_admob/getx_admob.dart';

class AppAdUnits {
  static List<AdmobUnitId> adUnits = [
    AppAdUnits.homeBanner,
    AppAdUnits.detailBanner,
    /// ... add more AdmobUnitId
  ];

  static AdmobUnitId homeBanner = AdmobUnitId(
    androidUnitId: 'ca-app-pub-3940256099942544/9214589741',
    iosUnitId: 'ca-app-pub-3940256099942544/2435281174',
  );

  static AdmobUnitId detailBanner = AdmobUnitId(
    androidUnitId: 'ca-app-pub-3940256099942544/9214589741',
    iosUnitId: 'ca-app-pub-3940256099942544/2435281174',
  );

  /// ... add more AdmobUnitId
}
```

main.dart
```dart
// ...
import 'package:example/app_ad_units.dart'; // <-- import getx admob ad units
import 'package:getx_admob/getx_admob.dart'; // <-- import getx admob
void main() async {
  // ensure initialized
  WidgetsFlutterBinding.ensureInitialized(); // <-- ensure initialized, MUST ADD THIS
  // ...
  // init admob service
  await Get.putAsync(
    () => AdmobService().init(
      adUnitIds: AppAdUnits.adUnits,
      // using for production
      appOpenAdUnitId: AdmobUnitId(
        androidUnitId: 'OPEN_APP_AD_UNIT_ID_ANDROID',
        iosUnitId: 'OPEN_APP_AD_UNIT_ID_IOS',
      ),
    ),
  );
  // ...
  runApp(const MyApp());
}
```

my_app.dart
```dart
import 'package:getx_admob/getx_admob.dart'; // <-- import getx admob
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // ...
      builder: (context, child) {
        return AdaptiveAdLoader(child: child); // <-- use adaptive ad loader
      },
    );
  }
}
```

home_page.dart
```dart
// ...
import 'package:example/app_ad_units.dart'; // <-- import getx admob ad units
import 'package:getx_admob/getx_admob.dart'; // <-- import getx admob

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: .center,
        children: [
          // ...
          AppBannerAd(AppAdUnits.homeBanner), // <-- add getx admob banner ad
          // ...
        ],
      ),
    );
  }
}
```

## VS Code launch.json
When you are use VS Code, you can use launch.json to enable or disable ad in your app.

It will using production ad by default.

launch.json example
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "getx_admob [disable ad]",
            "request": "launch",
            "type": "dart",
            "args": [
                "--dart-define",
                "ENABLE_AD=false"
            ]
        },
        {
            "name": "getx_admob [use debug ad]",
            "request": "launch",
            "type": "dart",
            "args": [
                "--dart-define",
                "DEBUG_AD=true"
            ]
        },
        {
            "name": "getx_admob [use production ad]",
            "request": "launch",
            "type": "dart"
        }
    ]
}
```

## Additional information

Welcome to contribute to this package.

https://github.com/LunaGao/getx_admob
