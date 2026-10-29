import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/app/app.dart';

void main() {
  testWidgets('HabitFlow app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HabitFlowApp(),
      ),
    );

    // Initial pump and settle
    await tester.pump();
    expect(find.byType(HabitFlowApp), findsOneWidget);
  });
}
