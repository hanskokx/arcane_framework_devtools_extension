import "package:arcane_framework_devtools_extension/src/common/arcane_bridge.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class FeatureFlagsPanel extends StatelessWidget {
  const FeatureFlagsPanel({required this.bridge, super.key});

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
        final features = snapshot.enabledFeatureFlags;
        if (features.isEmpty) {
          return const EmptyState(
            message: "No feature flags enabled.\n"
                "Enable flags in the app via Arcane.features.enableFeature(...).",
          );
        }

        return Column(
          children: [
            const SectionHeader(title: "Feature Flags"),
            Expanded(
              child: ListView.builder(
                itemCount: features.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: Text(features[index]),
                    subtitle: const Text("Enabled"),
                    trailing: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
