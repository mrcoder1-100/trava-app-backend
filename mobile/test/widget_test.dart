import 'package:flutter_test/flutter_test.dart';
import 'package:trava/main.dart';
import 'package:trava/core/constants.dart';

void main() {
  testWidgets('Trava smoke test verifies intro branding', (WidgetTester tester) async {
    await tester.pumpWidget(const TravaApp());
    await tester.pump();

    // Verify app name and tagline
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.tagline), findsOneWidget);
  });
}
