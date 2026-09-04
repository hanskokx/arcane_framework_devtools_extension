import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart" hide ThemeMode, ThemeData;
import "package:material_ui/material_ui.dart" show ThemeMode, ThemeData;

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
        const Divider(height: 32),
        const SectionHeader(title: "Theme Explorer"),
        _ThemeExplorerSection(
          label: "Light Theme",
          icon: Icons.light_mode,
          entries: _buildLightThemeEntries(),
        ),
        _ThemeExplorerSection(
          label: "Dark Theme",
          icon: Icons.dark_mode,
          entries: _buildDarkThemeEntries(),
        ),
      ],
    );
  }

  List<_ThemeCategory> _buildLightThemeEntries() =>
      _buildThemeEntries(Arcane.theme.light);

  List<_ThemeCategory> _buildDarkThemeEntries() =>
      _buildThemeEntries(Arcane.theme.dark);

  List<_ThemeCategory> _buildThemeEntries(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final iconTheme = theme.iconTheme;

    return [
      _ThemeCategory(
        label: "Color Scheme",
        entries: [
          _ThemeEntry("primary", colorScheme.primary),
          _ThemeEntry("onPrimary", colorScheme.onPrimary),
          _ThemeEntry("primaryContainer", colorScheme.primaryContainer),
          _ThemeEntry("onPrimaryContainer", colorScheme.onPrimaryContainer),
          _ThemeEntry("secondary", colorScheme.secondary),
          _ThemeEntry("onSecondary", colorScheme.onSecondary),
          _ThemeEntry("secondaryContainer", colorScheme.secondaryContainer),
          _ThemeEntry(
            "onSecondaryContainer",
            colorScheme.onSecondaryContainer,
          ),
          _ThemeEntry("tertiary", colorScheme.tertiary),
          _ThemeEntry("onTertiary", colorScheme.onTertiary),
          _ThemeEntry("tertiaryContainer", colorScheme.tertiaryContainer),
          _ThemeEntry("onTertiaryContainer", colorScheme.onTertiaryContainer),
          _ThemeEntry("error", colorScheme.error),
          _ThemeEntry("onError", colorScheme.onError),
          _ThemeEntry("errorContainer", colorScheme.errorContainer),
          _ThemeEntry("onErrorContainer", colorScheme.onErrorContainer),
          _ThemeEntry("surface", colorScheme.surface),
          _ThemeEntry("onSurface", colorScheme.onSurface),
          _ThemeEntry(
            "surfaceContainerLowest",
            colorScheme.surfaceContainerLowest,
          ),
          _ThemeEntry("surfaceContainerLow", colorScheme.surfaceContainerLow),
          _ThemeEntry("surfaceContainer", colorScheme.surfaceContainer),
          _ThemeEntry(
            "surfaceContainerHigh",
            colorScheme.surfaceContainerHigh,
          ),
          _ThemeEntry(
            "surfaceContainerHighest",
            colorScheme.surfaceContainerHighest,
          ),
          _ThemeEntry("onSurfaceVariant", colorScheme.onSurfaceVariant),
          _ThemeEntry("outline", colorScheme.outline),
          _ThemeEntry("outlineVariant", colorScheme.outlineVariant),
          _ThemeEntry("shadow", colorScheme.shadow),
          _ThemeEntry("scrim", colorScheme.scrim),
          _ThemeEntry("inverseSurface", colorScheme.inverseSurface),
          _ThemeEntry("onInverseSurface", colorScheme.onInverseSurface),
          _ThemeEntry("inversePrimary", colorScheme.inversePrimary),
          _ThemeEntry("surfaceTint", colorScheme.surfaceTint),
        ],
      ),
      _ThemeCategory(
        label: "Text Theme",
        entries: [
          _ThemeEntry("displayLarge", textTheme.displayLarge),
          _ThemeEntry("displayMedium", textTheme.displayMedium),
          _ThemeEntry("displaySmall", textTheme.displaySmall),
          _ThemeEntry("headlineLarge", textTheme.headlineLarge),
          _ThemeEntry("headlineMedium", textTheme.headlineMedium),
          _ThemeEntry("headlineSmall", textTheme.headlineSmall),
          _ThemeEntry("titleLarge", textTheme.titleLarge),
          _ThemeEntry("titleMedium", textTheme.titleMedium),
          _ThemeEntry("titleSmall", textTheme.titleSmall),
          _ThemeEntry("bodyLarge", textTheme.bodyLarge),
          _ThemeEntry("bodyMedium", textTheme.bodyMedium),
          _ThemeEntry("bodySmall", textTheme.bodySmall),
          _ThemeEntry("labelLarge", textTheme.labelLarge),
          _ThemeEntry("labelMedium", textTheme.labelMedium),
          _ThemeEntry("labelSmall", textTheme.labelSmall),
        ],
      ),
      _ThemeCategory(
        label: "Icon Theme",
        entries: [
          _ThemeEntry("color", iconTheme.color),
          _ThemeEntry("size", iconTheme.size),
          _ThemeEntry("opacity", iconTheme.opacity),
        ],
      ),
      _ThemeCategory(
        label: "General",
        entries: [
          _ThemeEntry("brightness", theme.brightness),
          _ThemeEntry("useMaterial3", theme.useMaterial3),
          _ThemeEntry("primaryColor", theme.primaryColor),
          _ThemeEntry("canvasColor", theme.canvasColor),
          _ThemeEntry(
            "scaffoldBackgroundColor",
            theme.scaffoldBackgroundColor,
          ),
          _ThemeEntry("cardColor", theme.cardColor),
          _ThemeEntry("dividerColor", theme.dividerColor),
          _ThemeEntry("shadowColor", theme.shadowColor),
          _ThemeEntry("splashColor", theme.splashColor),
          _ThemeEntry("highlightColor", theme.highlightColor),
          _ThemeEntry("hintColor", theme.hintColor),
          _ThemeEntry("focusColor", theme.focusColor),
          _ThemeEntry("hoverColor", theme.hoverColor),
          _ThemeEntry("disabledColor", theme.disabledColor),
        ],
      ),
    ];
  }
}

class _ThemeCategory {
  const _ThemeCategory({required this.label, required this.entries});

  final String label;
  final List<_ThemeEntry> entries;
}

class _ThemeEntry {
  const _ThemeEntry(this.label, this.value);

  final String label;
  final Object? value;
}

class _ThemeExplorerSection extends StatefulWidget {
  const _ThemeExplorerSection({
    required this.label,
    required this.icon,
    required this.entries,
  });

  final String label;
  final IconData icon;
  final List<_ThemeCategory> entries;

  @override
  State<_ThemeExplorerSection> createState() => _ThemeExplorerSectionState();
}

class _ThemeExplorerSectionState extends State<_ThemeExplorerSection> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(widget.icon, size: 18),
      title: Text(widget.label),
      children: widget.entries.map((category) {
        return _ThemeCategoryTile(category: category);
      }).toList(),
    );
  }
}

class _ThemeCategoryTile extends StatelessWidget {
  const _ThemeCategoryTile({required this.category});

  final _ThemeCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(
        category.label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: category.entries.map((entry) {
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 32, right: 16),
          title: Text(
            entry.label,
            style: theme.textTheme.bodySmall,
          ),
          subtitle: entry.value is Color
              ? _ColorSwatch(color: entry.value as Color)
              : Text(
                  entry.value.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: "monospace",
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        );
      }).toList(),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          color.toARGB32().toRadixString(16).padLeft(8, "0"),
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: "monospace",
            color: theme.colorScheme.onSurfaceVariant,
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
