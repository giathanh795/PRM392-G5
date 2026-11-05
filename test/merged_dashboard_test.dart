import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liverpool_pms/core/theme/app_theme.dart';
import 'package:liverpool_pms/providers/app_state_provider.dart';
import 'package:liverpool_pms/screens/dashboard/dashboard_screen.dart';

void main() {
  for (final width in [360.0, 1200.0]) {
    testWidgets('Merged Dashboard switches both views at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final state = AppStateProvider();
      await tester.runAsync(() async {
        while (!state.isInitialized) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
      });
      for (var i = 0; i < state.players.length; i++) {
        state.players[i] = state.players[i].copyWith(avatarUrl: '');
      }
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: DashboardScreen(onNavigateTab: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your club at a glance'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Command centre'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Club overview'));
      await tester.pumpAndSettle();
      expect(find.text('Your club at a glance'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }
}
