class AdBuildConfig {
  const AdBuildConfig({required this.enableAd, required bool debugAd})
    : debugAd = enableAd ? debugAd : false;

  const AdBuildConfig.fromEnvironment()
    : this(
        enableAd: const bool.fromEnvironment('ENABLE_AD', defaultValue: true),
        debugAd: const bool.fromEnvironment('DEBUG_AD', defaultValue: false),
      );

  final bool enableAd;
  final bool debugAd;
}
