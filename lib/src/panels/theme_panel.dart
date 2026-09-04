import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart" hide ThemeMode;
import "package:material_ui/material_ui.dart" show ThemeMode;

class ThemePanel extends StatefulWidget {
  const ThemePanel({super.key});

  @override
  State<ThemePanel> createState() => _ThemePanelState();
}

class _ThemePanelState extends State<ThemePanel> {
  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  StreamSubscription<dynamic>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    _subscription = Arcane.theme.themeModeChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = Arcane.theme.currentThemeMode;
    final isFollowingSystem = Arcane.theme.isFollowingSystemTheme;

    String modeLabel;
    Color modeColor;
    switch (mode) {
      case ThemeMode.light:
        modeLabel = "LIGHT";
        modeColor = Colors.amber;
      case ThemeMode.dark:
        modeLabel = "DARK";
        modeColor = Colors.indigo;
      case ThemeMode.system:
        modeLabel = "SYSTEM";
        modeColor = Colors.teal;
    }

    return ListView(
      children: [
        const SectionHeader(title: "Current Theme"),
        ServiceRow(
          title: "Theme Mode",
          value: modeLabel,
          valueColor: modeColor,
        ),
        ServiceRow(
          title: "Following System",
          value: isFollowingSystem ? "Yes" : "No",
          valueColor: isFollowingSystem ? Colors.green : Colors.orange,
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
                isActive: mode == ThemeMode.light && !isFollowingSystem,
                onPressed: () {
                  Arcane.theme.switchTheme(themeMode: ThemeMode.light);
                  setState(() {});
                },
              ),
              _ThemeActionButton(
                label: "Dark",
                icon: Icons.dark_mode,
                isActive: mode == ThemeMode.dark && !isFollowingSystem,
                onPressed: () {
                  Arcane.theme.switchTheme(themeMode: ThemeMode.dark);
                  setState(() {});
                },
              ),
              _ThemeActionButton(
                label: "Follow System",
                icon: Icons.brightness_auto,
                isActive: isFollowingSystem,
                onPressed: () {
                  Arcane.theme.followSystemTheme(context);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
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
