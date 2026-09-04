import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:material_ui/material_ui.dart";

class AuthenticationPanel extends StatefulWidget {
  const AuthenticationPanel({super.key});

  @override
  State<AuthenticationPanel> createState() => _AuthenticationPanelState();
}

class _AuthenticationPanelState extends State<AuthenticationPanel> {
  @override
  void initState() {
    super.initState();
    Arcane.auth.notifier.addListener(_onChanged);
    Arcane.auth.isSignedIn.addListener(_onChanged);
  }

  @override
  void dispose() {
    Arcane.auth.notifier.removeListener(_onChanged);
    Arcane.auth.isSignedIn.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = Arcane.auth.status;
    final isSignedIn = Arcane.auth.isSignedIn.value;
    final interfaceType = Arcane.auth.authInterface?.runtimeType.toString();

    Color statusColor;
    switch (status) {
      case AuthenticationStatus.authenticated:
        statusColor = Colors.green;
      case AuthenticationStatus.unauthenticated:
        statusColor = Colors.red;
      case AuthenticationStatus.unknown:
        statusColor = Colors.orange;
    }

    return ListView(
      children: [
        const SectionHeader(title: "Authentication Status"),
        ServiceRow(
          title: "Status",
          value: status.name.toUpperCase(),
          valueColor: statusColor,
        ),
        ServiceRow(
          title: "Signed In",
          value: isSignedIn ? "Yes" : "No",
          valueColor: isSignedIn ? Colors.green : Colors.red,
        ),
        ServiceRow(
          title: "Interface",
          value: interfaceType ?? "None registered",
          valueColor: interfaceType != null ? Colors.green : Colors.orange,
        ),
        const Divider(height: 32),
        const SectionHeader(title: "Debug Actions"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Arcane.auth.setAuthenticated();
                    setState(() {});
                  },
                  icon: const Icon(Icons.login, size: 16),
                  label: const Text("Set Authenticated"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Arcane.auth.setUnauthenticated();
                    setState(() {});
                  },
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text("Set Unauthenticated"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
