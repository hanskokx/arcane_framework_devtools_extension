import "package:arcane_framework_devtools_extension/src/common/arcane_bridge.dart";
import "package:arcane_framework_devtools_extension/src/common/connection_banner.dart";
import "package:arcane_framework_devtools_extension/src/panels/authentication_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/environment_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/feature_flags_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/logging_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/overview_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/services_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/theme_panel.dart";
import "package:flutter/material.dart";

class ArcaneDevToolsPage extends StatefulWidget {
  const ArcaneDevToolsPage({super.key});

  @override
  State<ArcaneDevToolsPage> createState() => _ArcaneDevToolsPageState();
}

class _ArcaneDevToolsPageState extends State<ArcaneDevToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ArcaneServiceBridge _bridge;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _bridge = ArcaneServiceBridge();
  }

  @override
  void dispose() {
    _bridge.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ConnectionBanner(),
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: "Overview", icon: Icon(Icons.dashboard_outlined)),
              Tab(text: "Services", icon: Icon(Icons.extension_outlined)),
              Tab(
                text: "Feature Flags",
                icon: Icon(Icons.flag_outlined),
              ),
              Tab(text: "Auth", icon: Icon(Icons.person_outline)),
              Tab(text: "Theme", icon: Icon(Icons.palette_outlined)),
              Tab(
                text: "Environment",
                icon: Icon(Icons.public_outlined),
              ),
              Tab(text: "Logs", icon: Icon(Icons.terminal_outlined)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OverviewPanel(bridge: _bridge),
              ServicesPanel(bridge: _bridge),
              FeatureFlagsPanel(bridge: _bridge),
              AuthenticationPanel(bridge: _bridge),
              ThemePanel(bridge: _bridge),
              EnvironmentPanel(bridge: _bridge),
              LoggingPanel(bridge: _bridge),
            ],
          ),
        ),
      ],
    );
  }
}
