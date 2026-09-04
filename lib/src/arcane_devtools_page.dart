import "package:arcane_framework_devtools_extension/src/panels/authentication_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/environment_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/feature_flags_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/logging_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/overview_panel.dart";
import "package:arcane_framework_devtools_extension/src/panels/theme_panel.dart";
import "package:material_ui/material_ui.dart";

class ArcaneDevToolsPage extends StatefulWidget {
  const ArcaneDevToolsPage({super.key});

  @override
  State<ArcaneDevToolsPage> createState() => _ArcaneDevToolsPageState();
}

class _ArcaneDevToolsPageState extends State<ArcaneDevToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: "Overview", icon: Icon(Icons.dashboard_outlined)),
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
            children: const [
              OverviewPanel(),
              FeatureFlagsPanel(),
              AuthenticationPanel(),
              ThemePanel(),
              EnvironmentPanel(),
              LoggingPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
