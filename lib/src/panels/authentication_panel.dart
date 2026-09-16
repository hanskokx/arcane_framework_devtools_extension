import "package:arcane_framework_devtools_extension/src/common/arcane_bridge.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class AuthenticationPanel extends StatelessWidget {
  const AuthenticationPanel({required this.bridge, super.key});

  final ArcaneServiceBridge bridge;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: bridge,
      builder: (context, _) {
        final snapshot = bridge.snapshot;
        if (snapshot == null) {
          return const EmptyState(
            message: "No state available yet.\n"
                "Connect to an arcane_framework app over the VM service.",
          );
        }
        final auth = snapshot.auth;
        final statusColor = _statusColor(auth.status);
        final interfaceRegistered = auth.interfaceType != null;

        return ListView(
          children: [
            const SectionHeader(title: "Authentication Status"),
            ServiceRow(
              title: "Status",
              value: auth.status.toUpperCase(),
              valueColor: statusColor,
            ),
            ServiceRow(
              title: "Signed In",
              value: auth.isSignedIn ? "Yes" : "No",
              valueColor: auth.isSignedIn ? Colors.green : Colors.red,
            ),
            ServiceRow(
              title: "Interface",
              value: auth.interfaceType ?? "None registered",
              valueColor: interfaceRegistered ? Colors.green : Colors.orange,
            ),
            const Divider(height: 32),
            const SectionHeader(title: "Debug Actions"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => bridge.setAuthAuthenticated(),
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text("Set Authenticated"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => bridge.setAuthUnauthenticated(),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text("Set Unauthenticated"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "authenticated":
        return Colors.green;
      case "unauthenticated":
        return Colors.red;
    }
    return Colors.orange;
  }
}
