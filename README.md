<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

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
void main() {
  // ensure initialized
  WidgetsFlutterBinding.ensureInitialized(); // <-- ensure initialized, MUST ADD THIS
  // ...
  Get.putAsync(() => AdmobService().init(AppAdUnits.adUnits)); // <-- init getx admob
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

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
