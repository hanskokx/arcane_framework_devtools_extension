import "package:arcane_framework_devtools_extension/src/common/arcane_bridge.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class EnvironmentPanel extends StatelessWidget {
  const EnvironmentPanel({required this.bridge, super.key});

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
        final environment = snapshot.environment;

        return ListView(
          children: [
            const SectionHeader(title: "Current Environment"),
            ServiceRow(
              title: "Environment",
              value: environment.name.toUpperCase(),
              valueColor: environment.isDebug ? Colors.orange : Colors.green,
            ),
            const Divider(height: 32),
            const SectionHeader(title: "Quick Actions"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => bridge.enableDebugMode(),
                      icon: const Icon(Icons.bug_report_outlined, size: 16),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: environment.isDebug
                            ? Theme.of(context).colorScheme.errorContainer
                            : null,
                        foregroundColor: environment.isDebug
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : null,
                      ),
                      label: const Text("Debug"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => bridge.disableDebugMode(),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !environment.isDebug
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        foregroundColor: !environment.isDebug
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                      label: const Text("Normal"),
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
}
