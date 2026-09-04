import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:material_ui/material_ui.dart";

class FeatureFlagsPanel extends StatefulWidget {
  const FeatureFlagsPanel({super.key});

  @override
  State<FeatureFlagsPanel> createState() => _FeatureFlagsPanelState();
}

class _FeatureFlagsPanelState extends State<FeatureFlagsPanel> {
  @override
  void initState() {
    super.initState();
    Arcane.features.notifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    Arcane.features.notifier.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final features = Arcane.features.enabledFeatures;
    if (features.isEmpty) {
      return const EmptyState(
        message: "No feature flags registered.\n"
            "Define an enum and enable flags via Arcane.features.enableFeature(...).",
      );
    }

    return Column(
      children: [
        const SectionHeader(title: "Feature Flags"),
        Expanded(
          child: ListView.builder(
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              final isEnabled = Arcane.features.isEnabled(feature);
              return SwitchListTile(
                title: Text(feature.name),
                subtitle: Text(
                  isEnabled ? "Enabled" : "Disabled",
                  style: TextStyle(
                    color: isEnabled ? Colors.green : Colors.orange,
                  ),
                ),
                value: isEnabled,
                onChanged: (value) {
                  if (value) {
                    Arcane.features.enableFeature(feature);
                  } else {
                    Arcane.features.disableFeature(feature);
                  }
                  setState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
