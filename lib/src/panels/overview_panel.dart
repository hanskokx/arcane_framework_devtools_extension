import "package:arcane_framework_devtools_extension/src/common/arcane_bridge.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class OverviewPanel extends StatelessWidget {
  const OverviewPanel({required this.bridge, super.key});

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
        return ListView(
          children: [
            const SectionHeader(title: "Registered Services"),
            if (snapshot.services.isEmpty)
              const EmptyState(message: "No services registered."),
            ...snapshot.services.map(
              (type) => ServiceRow(
                title: type,
                value: _summary(type, snapshot),
              ),
            ),
            const Divider(height: 32),
            const SectionHeader(title: "Logger"),
            _LoggerInfoSection(logging: snapshot.logging),
          ],
        );
      },
    );
  }

  String _summary(String type, ArcaneSnapshot snapshot) {
    switch (type) {
      case "ArcaneFeatureFlagService":
        return "${snapshot.enabledFeatureFlags.length} flag(s) enabled";
      case "ArcaneAuthenticationService":
        return "Status: ${snapshot.auth.status}";
      case "ArcaneThemeService":
        return "Mode: ${snapshot.theme.mode}";
      case "ArcaneEnvironmentService":
        return "Environment: ${snapshot.environment.name}";
    }
    return "active";
  }
}

class _LoggerInfoSection extends StatelessWidget {
  const _LoggerInfoSection({required this.logging});

  final LoggingSnapshot logging;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ServiceRow(
          title: "Initialized",
          value: logging.initialized ? "yes" : "no",
          valueColor: logging.initialized ? Colors.green : Colors.orange,
        ),
        ServiceRow(
          title: "Interfaces",
          value: logging.interfaces.length.toString(),
        ),
        ServiceRow(
          title: "Persistent metadata",
          value: logging.metadata.length.toString(),
        ),
      ],
    );
  }
}
