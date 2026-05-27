import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AdmobUnitId {
  late String _androidUnitId;
  late String _iosUnitId;

  AdmobUnitId({required String androidUnitId, required String iosUnitId}) {
    _androidUnitId = androidUnitId;
    _iosUnitId = iosUnitId;
  }

  String get productionUnitId {
    if (GetPlatform.isIOS) {
      return _iosUnitId;
    }
    if (GetPlatform.isAndroid) {
      return _androidUnitId;
    }
    throw PlatformException(code: 'platform_not_supported');
  }
}
