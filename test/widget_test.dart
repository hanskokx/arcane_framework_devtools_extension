import "package:arcane_framework_devtools_extension/main.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("Extension smoke test", (WidgetTester tester) async {
    await tester.pumpWidget(const ArcaneDevToolsExtension());
    expect(find.byType(ArcaneDevToolsExtension), findsOneWidget);
  });
}
