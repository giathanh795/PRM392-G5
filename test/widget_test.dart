import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liverpool_pms/main.dart';
import 'package:liverpool_pms/providers/app_state_provider.dart';

void main() {
  testWidgets('App starts at staff login and can toggle password visibility', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(),
        child: const LiverpoolPMSApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email / Gmail Ban Quản Trị'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng Nhập Vào Hệ Thống LFC'), findsOneWidget);
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
