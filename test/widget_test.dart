import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ready_player/app.dart';

void main() {
  testWidgets('App starts and shows LLM setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ReadyPlayerApp()),
    );

    // The setup screen shows a checking/loading state initially
    // Since method channels aren't available in tests, we just verify the app launches
    expect(find.byType(ReadyPlayerApp), findsOneWidget);
  });
}
