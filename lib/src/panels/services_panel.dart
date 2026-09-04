import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class ServicesPanel extends StatefulWidget {
  const ServicesPanel({super.key});

  @override
  State<ServicesPanel> createState() => _ServicesPanelState();
}

class _ServicesPanelState extends State<ServicesPanel> {
  @override
  void initState() {
    super.initState();
    Arcane.registry?.addListener(_onChanged);
  }

  @override
  void dispose() {
    Arcane.registry?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final services = Arcane.services;
    if (services.isEmpty) {
      return const EmptyState(
        message: "No services registered.\n"
            "Ensure ArcaneApp is wrapping your MaterialApp.",
      );
    }

    final builtIn =
        services.where((s) => _builtInTypes.contains(s.runtimeType)).toList();
    final user =
        services.where((s) => !_builtInTypes.contains(s.runtimeType)).toList();

    return ListView(
      children: [
        const SectionHeader(title: "Built-in Services"),
        if (builtIn.isEmpty)
          const _NoServicesNotice(message: "No built-in services registered."),
        ...builtIn.map(_serviceTile),
        const Divider(height: 32),
        const SectionHeader(title: "User Services"),
        if (user.isEmpty)
          const _NoServicesNotice(
            message: "No user services registered.",
          ),
        ...user.map(_serviceTile),
      ],
    );
  }

  static const Set<Type> _builtInTypes = {
    ArcaneFeatureFlagService,
    ArcaneAuthenticationService,
    ArcaneThemeService,
    ArcaneEnvironmentService,
  };

  Widget _serviceTile(ArcaneService service) {
    final type = service.runtimeType.toString();
    return _ServiceCard(service: service, typeName: type);
  }
}

class _ServiceCard extends StatefulWidget {
  const _ServiceCard({required this.service, required this.typeName});

  final ArcaneService service;
  final String typeName;

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = widget.service;
    final summary = _summarize(service);

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
            widget.typeName,
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
                "Runtime type: ${service.runtimeType}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          leading: _serviceIcon(service, theme),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ServiceDetailScreen(
                  service: service,
                  typeName: widget.typeName,
                ),
              ),
            );
          },
          trailing: Icon(
            Icons.chevron_right,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _serviceIcon(ArcaneService service, ThemeData theme) {
    final IconData icon;
    final Color color;
    if (service is ArcaneFeatureFlagService) {
      icon = Icons.flag_outlined;
      color = theme.colorScheme.primary;
    } else if (service is ArcaneAuthenticationService) {
      icon = Icons.person_outline;
      color = theme.colorScheme.primary;
    } else if (service is ArcaneThemeService) {
      icon = Icons.palette_outlined;
      color = theme.colorScheme.primary;
    } else if (service is ArcaneEnvironmentService) {
      icon = Icons.public_outlined;
      color = theme.colorScheme.primary;
    } else {
      icon = Icons.extension_outlined;
      color = theme.colorScheme.secondary;
    }
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

  String _summarize(ArcaneService service) {
    if (service is ArcaneFeatureFlagService) {
      return "${service.enabledFeatures.length} flag(s) enabled";
    }
    if (service is ArcaneAuthenticationService) {
      final status = service.status;
      return "Status: ${status.name}";
    }
    if (service is ArcaneThemeService) {
      return "Mode: ${service.currentThemeMode.name}";
    }
    if (service is ArcaneEnvironmentService) {
      return "Environment: ${service.current.name}";
    }
    return "Type: ${service.runtimeType}";
  }
}

class _ServiceDetailScreen extends StatelessWidget {
  const _ServiceDetailScreen({
    required this.service,
    required this.typeName,
  });

  final ArcaneService service;
  final String typeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
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
                    const _DetailItem(label: "Type", value: "Custom"),
                    _DetailItem(label: "Actual Type", value: typeName),
                    const _DetailItem(label: "Disposable", value: "Yes"),
                  ],
                ),
                const SizedBox(height: 8),
                _DetailBlock(
                  title: "Service State",
                  children: _stateItems(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _stateItems() {
    if (service is ArcaneFeatureFlagService) {
      final s = service as ArcaneFeatureFlagService;
      final features = s.enabledFeatures;
      return [
        _DetailItem(label: "Enabled Flags", value: features.length.toString()),
        if (features.isEmpty)
          const _DetailItem(label: "Flags", value: "(none)")
        else
          ...features.map(
            (f) => _DetailItem(label: f.runtimeType.toString(), value: f.name),
          ),
      ];
    }
    if (service is ArcaneAuthenticationService) {
      final s = service as ArcaneAuthenticationService;
      return [
        _DetailItem(label: "Status", value: s.status.name),
        _DetailItem(label: "Signed In", value: s.isSignedIn.value.toString()),
        _DetailItem(
          label: "Interface",
          value: s.authInterface?.runtimeType.toString() ?? "(none)",
        ),
      ];
    }
    if (service is ArcaneThemeService) {
      final s = service as ArcaneThemeService;
      return [
        _DetailItem(label: "Mode", value: s.currentThemeMode.name),
        _DetailItem(
          label: "Following System",
          value: s.isFollowingSystemTheme.toString(),
        ),
      ];
    }
    if (service is ArcaneEnvironmentService) {
      final s = service as ArcaneEnvironmentService;
      return [
        _DetailItem(label: "Environment", value: s.current.name),
        _DetailItem(
          label: "Is Debug",
          value: s.current.isDebug.toString(),
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
