enum AdmobDiagnosticType {
  appOpenLoadStarted,
  appOpenLoaded,
  appOpenLoadFailed,
  appOpenUnavailable,
  appOpenAlreadyShowing,
  appOpenExpired,
  appOpenShowRequested,
  appOpenShown,
  appOpenShowFailed,
  appOpenDismissed,
}

class AdmobDiagnosticEvent {
  const AdmobDiagnosticEvent({
    required this.type,
    required this.timestamp,
    required this.adUnitId,
    this.duration,
    this.errorCode,
    this.errorDomain,
    this.errorMessage,
  });

  final AdmobDiagnosticType type;
  final DateTime timestamp;
  final String adUnitId;
  final Duration? duration;
  final int? errorCode;
  final String? errorDomain;
  final String? errorMessage;

  @override
  String toString() {
    final details = <String>[
      'type=${type.name}',
      'adUnitId=$adUnitId',
      'timestamp=${timestamp.toIso8601String()}',
      if (duration != null) 'durationMs=${duration!.inMilliseconds}',
      if (errorCode != null) 'errorCode=$errorCode',
      if (errorDomain != null) 'errorDomain=$errorDomain',
      if (errorMessage != null) 'errorMessage=$errorMessage',
    ];
    return 'AdmobDiagnosticEvent(${details.join(', ')})';
  }
}

typedef AdmobDiagnosticCallback = void Function(AdmobDiagnosticEvent event);
