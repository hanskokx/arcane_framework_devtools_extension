import "dart:async";
import "dart:convert";

import "package:devtools_extensions/devtools_extensions.dart";
import "package:flutter/foundation.dart";
import "package:vm_service/vm_service.dart" show RPCError, Response;

/// A snapshot of live state read from a connected arcane_framework app.
///
/// Immutable; produced by [ArcaneServiceBridge] as it polls the app's
/// `ext.arcane.devtools.invoke` VM service extension.
@immutable
class ArcaneSnapshot {
  const ArcaneSnapshot({
    required this.services,
    required this.enabledFeatureFlags,
    required this.auth,
    required this.theme,
    required this.environment,
    required this.logging,
    required this.recentLogs,
  });

  const ArcaneSnapshot.empty()
      : services = const [],
        enabledFeatureFlags = const [],
        auth = const AuthSnapshot.empty(),
        theme = const ThemeSnapshot.empty(),
        environment = const EnvironmentSnapshot.empty(),
        logging = const LoggingSnapshot.empty(),
        recentLogs = const [];

  /// The runtime type names of all registered services.
  final List<String> services;

  /// The names of the currently enabled feature flags.
  final List<String> enabledFeatureFlags;

  final AuthSnapshot auth;
  final ThemeSnapshot theme;
  final EnvironmentSnapshot environment;
  final LoggingSnapshot logging;

  /// The most recent log events, oldest first.
  final List<ArcaneLogEntry> recentLogs;
}

@immutable
class AuthSnapshot {
  const AuthSnapshot({
    required this.status,
    required this.isSignedIn,
    required this.interfaceType,
  });

  const AuthSnapshot.empty()
      : status = "unknown",
        isSignedIn = false,
        interfaceType = null;

  factory AuthSnapshot.fromJson(Map<String, dynamic> json) => AuthSnapshot(
        status: _string(json["status"], "unknown"),
        isSignedIn: _bool(json["isSignedIn"]),
        interfaceType: _nullableString(json["interfaceType"]),
      );

  final String status;
  final bool isSignedIn;
  final String? interfaceType;
}

@immutable
class ThemeSnapshot {
  const ThemeSnapshot({
    required this.mode,
    required this.followingSystem,
    required this.customThemeRegistered,
  });

  const ThemeSnapshot.empty()
      : mode = "system",
        followingSystem = false,
        customThemeRegistered = false;

  factory ThemeSnapshot.fromJson(Map<String, dynamic> json) => ThemeSnapshot(
        mode: _string(json["mode"], "system"),
        followingSystem: _bool(json["followingSystem"]),
        customThemeRegistered: _bool(json["customThemeRegistered"]),
      );

  final String mode;
  final bool followingSystem;
  final bool customThemeRegistered;
}

@immutable
class EnvironmentSnapshot {
  const EnvironmentSnapshot({required this.name, required this.isDebug});

  const EnvironmentSnapshot.empty()
      : name = "normal",
        isDebug = false;

  factory EnvironmentSnapshot.fromJson(Map<String, dynamic> json) =>
      EnvironmentSnapshot(
        name: _string(json["name"], "normal"),
        isDebug: _bool(json["isDebug"]),
      );

  final String name;
  final bool isDebug;
}

@immutable
class LoggingSnapshot {
  const LoggingSnapshot({
    required this.initialized,
    required this.interfaces,
    required this.metadata,
  });

  const LoggingSnapshot.empty()
      : initialized = false,
        interfaces = const [],
        metadata = const {};

  factory LoggingSnapshot.fromJson(Map<String, dynamic> json) =>
      LoggingSnapshot(
        initialized: _bool(json["initialized"]),
        interfaces: _stringList(json["interfaces"]) ?? const [],
        metadata: _stringMap(json["metadata"]) ?? const {},
      );

  final bool initialized;

  /// The runtime type names of all registered logging interfaces.
  final List<String> interfaces;

  /// The logger's persistent metadata.
  final Map<String, String> metadata;
}

@immutable
class ArcaneLogEntry {
  const ArcaneLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.module,
    required this.method,
    required this.message,
    required this.metadata,
  });

  factory ArcaneLogEntry.fromJson(Map<String, dynamic> json) => ArcaneLogEntry(
        id: _int(json["id"]),
        timestamp: _string(json["timestamp"]),
        level: _string(json["level"], "debug"),
        module: _nullableString(json["module"]),
        method: _nullableString(json["method"]),
        message: _string(json["message"]),
        metadata: _stringMap(json["metadata"]) ?? const {},
      );

  final int id;
  final String timestamp;
  final String level;
  final String? module;
  final String? method;
  final String message;
  final Map<String, String> metadata;
}

/// Polls the connected app's `ext.arcane.devtools.invoke` VM service extension
/// and exposes the current [ArcaneSnapshot] to listeners.
///
/// While connected, state is refreshed every [_pollInterval]. Calls that fail
/// (e.g. the app does not use arcane_framework, or the connection drops
/// mid-poll) are ignored and the last known snapshot is retained.
class ArcaneServiceBridge extends ChangeNotifier {
  ArcaneServiceBridge() {
    serviceManager.connectedState.addListener(_onConnectionChanged);
    serviceManager.isolateManager.mainIsolate.addListener(_onConnectionChanged);
    _onConnectionChanged();
  }

  /// The arcane_framework service extension, mirroring the standard
  /// `method` + `params` invoke protocol.
  static const String _serviceExtension = "ext.arcane.devtools.invoke";

  static const String _methodParameter = "method";
  static const String _paramsParameter = "params";

  static const Duration _pollInterval = Duration(seconds: 2);

  Timer? _pollTimer;
  bool _polling = false;
  bool _disposed = false;
  ArcaneSnapshot? _snapshot;

  /// The most recent snapshot read from the app, or `null` before the first
  /// successful poll.
  ArcaneSnapshot? get snapshot => _snapshot;

  /// Whether the VM service is currently connected to an app.
  bool get connected => serviceManager.connectedState.value.connected;

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    serviceManager.connectedState.removeListener(_onConnectionChanged);
    serviceManager.isolateManager.mainIsolate
        .removeListener(_onConnectionChanged);
    super.dispose();
  }

  void _onConnectionChanged() {
    final mainIsolate = serviceManager.isolateManager.mainIsolate.value;
    final shouldPoll = connected && mainIsolate != null;

    if (shouldPoll && _pollTimer == null) {
      unawaited(_poll());
      _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_poll()));
      return;
    }

    if (!shouldPoll && _pollTimer != null) {
      _pollTimer?.cancel();
      _pollTimer = null;
      _snapshot = null;
      notifyListeners();
    }
  }

  Future<void> _poll() async {
    if (_polling || _disposed || !connected) return;
    _polling = true;
    try {
      final result = await _fetchEverything();
      if (_disposed) return;
      if (result != null) {
        _snapshot = result;
        notifyListeners();
      }
    } finally {
      _polling = false;
    }
  }

  Future<ArcaneSnapshot?> _fetchEverything() async {
    final result = await _invoke("overview");
    if (result == null) return null;

    final previous = _snapshot;
    final List<String>? previousServices = previous?.services;
    final List<String>? previousFlags = previous?.enabledFeatureFlags;
    final List<ArcaneLogEntry>? previousLogs = previous?.recentLogs;

    final authJson = result["auth"];
    final themeJson = result["theme"];
    final environmentJson = result["environment"];
    final loggingJson = result["logging"];
    final featureFlagsJson = result["featureFlags"];

    return ArcaneSnapshot(
      services: _stringList(result["services"]) ?? previousServices ?? const [],
      enabledFeatureFlags: featureFlagsJson is Map<String, dynamic>
          ? _stringList(featureFlagsJson["enabled"]) ??
              previousFlags ??
              const []
          : previousFlags ?? const [],
      auth: authJson is Map<String, dynamic>
          ? AuthSnapshot.fromJson(authJson)
          : previous?.auth ?? const AuthSnapshot.empty(),
      theme: themeJson is Map<String, dynamic>
          ? ThemeSnapshot.fromJson(themeJson)
          : previous?.theme ?? const ThemeSnapshot.empty(),
      environment: environmentJson is Map<String, dynamic>
          ? EnvironmentSnapshot.fromJson(environmentJson)
          : previous?.environment ?? const EnvironmentSnapshot.empty(),
      logging: loggingJson is Map<String, dynamic>
          ? LoggingSnapshot.fromJson(loggingJson)
          : previous?.logging ?? const LoggingSnapshot.empty(),
      recentLogs: _logEntries(result["recentLogs"]) ?? previousLogs ?? const [],
    );
  }

  Future<Map<String, dynamic>?> _invoke(
    String method, {
    Map<String, Object?> params = const {},
  }) async {
    final service = serviceManager.service;
    final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;
    if (service == null || isolateId == null) return null;

    try {
      final Response response = await service.callServiceExtension(
        _serviceExtension,
        isolateId: isolateId,
        args: {
          _methodParameter: method,
          _paramsParameter: jsonEncode(params),
        },
      );
      final Object? result = response.json?["result"];
      Object? payload = result;
      if (result is String) {
        try {
          payload = jsonDecode(result);
        } on FormatException {
          return null;
        }
      }
      if (payload is Map<String, dynamic>) {
        final Object? type = payload["type"];
        if (type == "error") return null;
        if (type == "result") {
          final Object? inner = payload["result"];
          return inner is Map<String, dynamic> ? inner : null;
        }
        return payload;
      }
    } on RPCError {
      // The extension is not available on this isolate (e.g. the app does not
      // use arcane_framework). Keep showing the stale snapshot.
    } catch (_) {
      // The connection vanished mid-call. Keep showing the stale snapshot.
    }
    return null;
  }

  Future<void> setAuthAuthenticated() => _runAction(
        "set_auth_status",
        params: {"status": "authenticated"},
      );

  Future<void> setAuthUnauthenticated() => _runAction(
        "set_auth_status",
        params: {"status": "unauthenticated"},
      );

  Future<void> setThemeMode(String mode) => _runAction(
        "set_theme_mode",
        params: {"mode": mode},
      );

  Future<void> enableDebugMode() => _runAction(
        "set_environment",
        params: {"name": "debug"},
      );

  Future<void> disableDebugMode() => _runAction(
        "set_environment",
        params: {"name": "normal"},
      );

  Future<void> _runAction(
    String method, {
    Map<String, Object?> params = const {},
  }) async {
    await _invoke(method, params: params);
    await _poll();
  }
}

String _string(Object? value, [String fallback = ""]) =>
    value is String ? value : fallback;

String? _nullableString(Object? value) => value is String ? value : null;

bool _bool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

int _int(Object? value, [int fallback = 0]) => value is int ? value : fallback;

List<String>? _stringList(Object? value) {
  if (value is List) return value.whereType<String>().toList();
  return null;
}

Map<String, String>? _stringMap(Object? value) {
  if (value is Map) {
    return {
      for (final Object? key in value.keys)
        key.toString(): value[key].toString(),
    };
  }
  return null;
}

List<ArcaneLogEntry>? _logEntries(Object? value) {
  if (value is! List) return null;
  return [
    for (final Object? item in value)
      if (item is Map<String, dynamic>) ArcaneLogEntry.fromJson(item),
  ];
}
