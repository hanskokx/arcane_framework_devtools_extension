import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:material_ui/material_ui.dart";

class EnvironmentPanel extends StatefulWidget {
  const EnvironmentPanel({super.key});

  @override
  State<EnvironmentPanel> createState() => _EnvironmentPanelState();
}

class _EnvironmentPanelState extends State<EnvironmentPanel> {
  @override
  void initState() {
    super.initState();
    Arcane.environment.notifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    Arcane.environment.notifier.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = Arcane.environment.current;
    final isDebug = current == Environment.debug;

    return ListView(
      children: [
        const SectionHeader(title: "Current Environment"),
        ServiceRow(
          title: "Environment",
          value: current.name.toUpperCase(),
          valueColor: isDebug ? Colors.orange : Colors.green,
        ),
        const Divider(height: 32),
        const SectionHeader(title: "Quick Actions"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Arcane.environment.enableDebugMode();
                    setState(() {});
                  },
                  icon: const Icon(Icons.bug_report_outlined, size: 16),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDebug
                        ? Theme.of(context).colorScheme.errorContainer
                        : null,
                    foregroundColor: isDebug
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : null,
                  ),
                  label: const Text("Debug"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Arcane.environment.disableDebugMode();
                    setState(() {});
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: !isDebug
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    foregroundColor: !isDebug
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
  }
}
