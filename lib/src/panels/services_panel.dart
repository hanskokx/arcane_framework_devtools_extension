import "package:arcane_framework_devtools_extension/src/common/arcane_bridge.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class ServicesPanel extends StatelessWidget {
  const ServicesPanel({required this.bridge, super.key});

  final ArcaneServiceBridge bridge;

  static const Set<String> _builtInTypes = {
    "ArcaneFeatureFlagService",
    "ArcaneAuthenticationService",
    "ArcaneThemeService",
    "ArcaneEnvironmentService",
  };

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
        final services = snapshot.services;
        if (services.isEmpty) {
          return const EmptyState(
            message: "No services registered.",
          );
        }

        final builtIn = services.where(_builtInTypes.contains).toList();
        final user =
            services.where((type) => !_builtInTypes.contains(type)).toList();

        return ListView(
          children: [
            const SectionHeader(title: "Built-in Services"),
            if (builtIn.isEmpty)
              const _NoServicesNotice(
                message: "No built-in services registered.",
              ),
            ...builtIn.map((type) => _serviceCard(context, type, snapshot)),
            const Divider(height: 32),
            const SectionHeader(title: "User Services"),
            if (user.isEmpty)
              const _NoServicesNotice(message: "No user services registered."),
            ...user.map((type) => _serviceCard(context, type, snapshot)),
          ],
        );
      },
    );
  }

  Widget _serviceCard(
    BuildContext context,
    String type,
    ArcaneSnapshot snapshot,
  ) {
    return _ServiceCard(
      typeName: type,
      summary: _summary(type, snapshot),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ServiceDetailScreen(
              bridge: bridge,
              typeName: type,
            ),
          ),
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
    return "Type: $type";
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.typeName,
    required this.summary,
    required this.onTap,
  });

  final String typeName;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          title: Text(
            typeName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(summary),
              ],
              const SizedBox(height: 2),
              Text(
                "Runtime type: $typeName",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          leading: _serviceIcon(typeName, theme),
          onTap: onTap,
          trailing: Icon(
            Icons.chevron_right,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _serviceIcon(String typeName, ThemeData theme) {
    final IconData icon;
    switch (typeName) {
      case "ArcaneFeatureFlagService":
        icon = Icons.flag_outlined;
      case "ArcaneAuthenticationService":
        icon = Icons.person_outline;
      case "ArcaneThemeService":
        icon = Icons.palette_outlined;
      case "ArcaneEnvironmentService":
        icon = Icons.public_outlined;
      default:
        icon = Icons.extension_outlined;
    }
    final color = icon == Icons.extension_outlined
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _ServiceDetailScreen extends StatelessWidget {
  const _ServiceDetailScreen({required this.bridge, required this.typeName});

  final ArcaneServiceBridge bridge;
  final String typeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: ListenableBuilder(
        listenable: bridge,
        builder: (context, _) {
          final snapshot = bridge.snapshot;
          return Column(
            children: [
              Material(
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        typeName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _DetailBlock(
                      title: "Runtime Type",
                      children: [
                        const _DetailItem(label: "Type", value: "Service"),
                        _DetailItem(label: "Actual Type", value: typeName),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (snapshot != null)
                      _DetailBlock(
                        title: "Service State",
                        children: _stateItems(snapshot),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _stateItems(ArcaneSnapshot snapshot) {
    switch (typeName) {
      case "ArcaneFeatureFlagService":
        final flags = snapshot.enabledFeatureFlags;
        return [
          _DetailItem(label: "Enabled Flags", value: flags.length.toString()),
          if (flags.isEmpty)
            const _DetailItem(label: "Flags", value: "(none)")
          else
            ...flags.map((flag) => _DetailItem(label: "Flag", value: flag)),
        ];
      case "ArcaneAuthenticationService":
        return [
          _DetailItem(label: "Status", value: snapshot.auth.status),
          _DetailItem(
            label: "Signed In",
            value: snapshot.auth.isSignedIn.toString(),
          ),
          _DetailItem(
            label: "Interface",
            value: snapshot.auth.interfaceType ?? "(none)",
          ),
        ];
      case "ArcaneThemeService":
        return [
          _DetailItem(label: "Mode", value: snapshot.theme.mode),
          _DetailItem(
            label: "Following System",
            value: snapshot.theme.followingSystem.toString(),
          ),
          _DetailItem(
            label: "Custom Themes",
            value: snapshot.theme.customThemeRegistered ? "Yes" : "No",
          ),
        ];
      case "ArcaneEnvironmentService":
        return [
          _DetailItem(label: "Environment", value: snapshot.environment.name),
          _DetailItem(
            label: "Is Debug",
            value: snapshot.environment.isDebug.toString(),
          ),
        ];
    }
    return const [
      _DetailItem(label: "Custom service", value: "No standard state"),
    ];
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoServicesNotice extends StatelessWidget {
  const _NoServicesNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}
