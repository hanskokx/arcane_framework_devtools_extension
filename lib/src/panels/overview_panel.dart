import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class OverviewPanel extends StatelessWidget {
  const OverviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Arcane.registry ?? ValueNotifier<List<ArcaneService>>([]),
      builder: (context, _) {
        final services = Arcane.services;
        if (services.isEmpty) {
          return const EmptyState(
            message: "No Arcane services found.\n"
                "Ensure ArcaneApp is wrapping your MaterialApp.",
          );
        }
        return ListView(
          children: [
            const SectionHeader(title: "Registered Services"),
            ...services.map(_ServiceTile.new),
            const Divider(height: 32),
            const SectionHeader(title: "Logger"),
            _LoggerInfoTile(logger: Arcane.logger),
          ],
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile(this.service);

  final ArcaneService service;

  @override
  Widget build(BuildContext context) {
    final type = service.runtimeType.toString();
    String summary;
    Color? color;

    if (service is ArcaneFeatureFlagService) {
      final count =
          (service as ArcaneFeatureFlagService).enabledFeatures.length;
      summary = "$count flag(s) enabled";
    } else if (service is ArcaneAuthenticationService) {
      final status = (service as ArcaneAuthenticationService).status;
      summary = status.name;
      color = status.isAuthenticated ? Colors.green : Colors.orange;
    } else if (service is ArcaneThemeService) {
      final mode = (service as ArcaneThemeService).currentThemeMode;
      summary = mode.name;
    } else if (service is ArcaneEnvironmentService) {
      summary = (service as ArcaneEnvironmentService).current.name;
    } else {
      summary = "active";
    }

    return ServiceRow(title: type, value: summary, valueColor: color);
  }
}

class _LoggerInfoTile extends StatelessWidget {
  const _LoggerInfoTile({required this.logger});

  final ArcaneLogger logger;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ServiceRow(
          title: "Initialized",
          value: logger.initialized ? "yes" : "no",
          valueColor: logger.initialized ? Colors.green : Colors.orange,
        ),
        ServiceRow(
          title: "Interfaces",
          value: logger.interfaces.length.toString(),
        ),
        ServiceRow(
          title: "Persistent metadata",
          value: logger.additionalMetadata.length.toString(),
        ),
      ],
    );
  }
}
