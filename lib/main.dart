import "package:arcane_framework_devtools_extension/src/arcane_devtools_page.dart";
import "package:devtools_extensions/devtools_extensions.dart";
import "package:flutter/widgets.dart";

void main() {
  runApp(const ArcaneDevToolsExtension());
}

class ArcaneDevToolsExtension extends StatelessWidget {
  const ArcaneDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: ArcaneDevToolsPage(),
    );
  }
}
