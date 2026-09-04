import "package:devtools_app_shared/service.dart";
import "package:devtools_extensions/devtools_extensions.dart";
import "package:flutter/material.dart";

const _simulatedEnvironmentEnabled =
    bool.fromEnvironment("use_simulated_environment");

/// A banner that reflects the current VM service connection state.
///
/// The [DevToolsExtension] framework automatically establishes and tears down
/// the VM service connection as the connected app comes and goes. This widget
/// listens to [serviceManager] state so that it appears with useful guidance
/// when no app is connected, and disappears once a connection is available.
class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({super.key});

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  ConnectedState _connected = const ConnectedState(false);
  String? _serviceUri;
  String? _sdkVersion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = serviceManager.connectedState;
    _refresh(state.value);
    state.addListener(_onConnectedStateChanged);
  }

  @override
  void dispose() {
    serviceManager.connectedState.removeListener(_onConnectedStateChanged);
    super.dispose();
  }

  void _onConnectedStateChanged() {
    _refresh(serviceManager.connectedState.value);
    setState(() {});
  }

  void _refresh(ConnectedState state) {
    _connected = state;
    _serviceUri = serviceManager.serviceUri;
    _sdkVersion = serviceManager.sdkVersion;
  }

  @override
  Widget build(BuildContext context) {
    if (!_connected.connected) {
      return const _DisconnectedBanner();
    }
    return _ConnectedChip(
      serviceUri: _serviceUri,
      sdkVersion: _sdkVersion,
    );
  }
}

/// A compact pill shown while an app is connected to the VM service.
class _ConnectedChip extends StatelessWidget {
  const _ConnectedChip({this.serviceUri, this.sdkVersion});

  final String? serviceUri;
  final String? sdkVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      if (sdkVersion case final version?) "SDK $version",
      if (serviceUri case final uri?) uri,
    ].join(" · ");
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              details.isEmpty
                  ? "Connected to an arcane_framework app."
                  : details,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A prominent banner shown when no app is connected to the VM service.
class _DisconnectedBanner extends StatelessWidget {
  const _DisconnectedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "No app connected",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _simulatedEnvironmentEnabled
                        ? "This extension inspects runtime state from an "
                            "arcane_framework app, read over the VM service. "
                            "Connect a VM service URI above."
                        : "This extension inspects runtime state from an "
                            "arcane_framework app, read over the VM service. "
                            "Start such an app and open this extension from "
                            "DevTools.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
