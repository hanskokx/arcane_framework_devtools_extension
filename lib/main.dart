import "dart:async";

import "package:arcane_framework_devtools_extension/src/arcane_devtools_page.dart";
import "package:devtools_app_shared/service.dart";
import "package:devtools_app_shared/ui.dart";
import "package:devtools_app_shared/utils.dart";
import "package:devtools_extensions/devtools_extensions.dart" hide extensionManager;
import "package:material_ui/material_ui.dart";
import "package:web/web.dart" hide Text;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initExtensionFramework();
  runApp(const ArcaneDevToolsExtensionApp());
}

void _initExtensionFramework() {
  setGlobal(ExtensionManager, ExtensionManager());
  setGlobal(ServiceManager, ServiceManager());
  setGlobal(DTDManager, DTDManager());
  setGlobal(IdeTheme, getIdeTheme());
  extensionManager._init();
}

class ArcaneDevToolsExtensionApp extends StatefulWidget {
  const ArcaneDevToolsExtensionApp({super.key});

  @override
  State<ArcaneDevToolsExtensionApp> createState() =>
      _ArcaneDevToolsExtensionAppState();
}

class _ArcaneDevToolsExtensionAppState
    extends State<ArcaneDevToolsExtensionApp> {
  @override
  void initState() {
    super.initState();
    extensionManager.darkThemeEnabled.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    extensionManager.darkThemeEnabled.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = extensionManager.darkThemeEnabled.value;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeFor(
        isDarkTheme: false,
        ideTheme: ideTheme,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
        ),
      ),
      darkTheme: themeFor(
        isDarkTheme: true,
        ideTheme: ideTheme,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
        ),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const ArcaneDevToolsPage(),
    );
  }
}
