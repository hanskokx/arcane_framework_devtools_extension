import "package:arcane_framework_devtools_extension/src/common/arcane_bridge.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class ThemePanel extends StatelessWidget {
  const ThemePanel({required this.bridge, super.key});

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
        final theme = snapshot.theme;
        final modeColor = _modeColor(theme.mode);

        return ListView(
          children: [
            const SectionHeader(title: "Current Theme"),
            ServiceRow(
              title: "Theme Mode",
              value: theme.mode.toUpperCase(),
              valueColor: modeColor,
            ),
            ServiceRow(
              title: "Following System",
              value: theme.followingSystem ? "Yes" : "No",
              valueColor: theme.followingSystem ? Colors.green : Colors.orange,
            ),
            ServiceRow(
              title: "Custom Themes",
              value: theme.customThemeRegistered ? "Yes" : "No",
              valueColor:
                  theme.customThemeRegistered ? Colors.green : Colors.orange,
            ),
            const Divider(height: 32),
            const SectionHeader(title: "Quick Actions"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ThemeActionButton(
                    label: "Light",
                    icon: Icons.light_mode,
                    isActive: theme.mode == "light" && !theme.followingSystem,
                    onPressed: () => bridge.setThemeMode("light"),
                  ),
                  _ThemeActionButton(
                    label: "Dark",
                    icon: Icons.dark_mode,
                    isActive: theme.mode == "dark" && !theme.followingSystem,
                    onPressed: () => bridge.setThemeMode("dark"),
                  ),
                  _ThemeActionButton(
                    label: "System",
                    icon: Icons.brightness_auto,
                    isActive: theme.mode == "system" || theme.followingSystem,
                    onPressed: () => bridge.setThemeMode("system"),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color _modeColor(String mode) {
    switch (mode) {
      case "light":
        return Colors.amber;
      case "dark":
        return Colors.indigo;
    }
    return Colors.teal;
  }
}

class _ThemeActionButton extends StatelessWidget {
  const _ThemeActionButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isActive ? Theme.of(context).colorScheme.primaryContainer : null,
        foregroundColor:
            isActive ? Theme.of(context).colorScheme.onPrimaryContainer : null,
      ),
      label: Text(label),
    );
  }
}
