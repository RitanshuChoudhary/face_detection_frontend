import 'package:flutter_test/flutter_test.dart';
import 'package:attendence_app/main.dart';

void main() {
  testWidgets('FaceTrackApp initial launch compilation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FaceTrackApp());

    // Verify splash elements exist or load without crashes
    expect(find.byType(FaceTrackApp), findsOneWidget);
  });
}
