import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liverpool_pms/main.dart';

void main() {
  testWidgets('App starts at staff login and can toggle password visibility', (
    tester,
  ) async {
    await tester.pumpWidget(const LiverpoolPMSApp());
    expect(find.text('Staff Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In to LFC Management'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
  });
}
