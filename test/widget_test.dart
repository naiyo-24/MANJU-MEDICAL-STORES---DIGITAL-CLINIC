import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manju_medical/main.dart';

void main() {
  testWidgets('App smoke test - mounts successfully', (WidgetTester tester) async {
    // Build our app inside ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SirfBillApp()));
    expect(find.byType(SirfBillApp), findsOneWidget);
  });
}
