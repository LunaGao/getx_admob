import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'admob_service.dart';

class AdaptiveAdLoader extends StatefulWidget {
  const AdaptiveAdLoader({required this.child, super.key});

  final Widget? child;

  @override
  State<AdaptiveAdLoader> createState() => _AdaptiveAdLoaderState();
}

class _AdaptiveAdLoaderState extends State<AdaptiveAdLoader>
    with WidgetsBindingObserver {
  int? _lastRequestedWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Start observing
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Clean up
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Get.find<AdmobService>().showAppOpenAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width > 0 && width != _lastRequestedWidth) {
      _lastRequestedWidth = width;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !Get.isRegistered<AdmobService>()) {
          return;
        }
        // 这里载入所有的广告数据
        Get.find<AdmobService>().loadAllAds(width);
      });
    }
    return widget.child ?? const SizedBox.shrink();
  }
}
