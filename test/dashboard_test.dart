import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liverpool_pms/core/theme/app_theme.dart';
import 'package:liverpool_pms/models/training_session.dart';
import 'package:liverpool_pms/providers/app_state_provider.dart';
import 'package:liverpool_pms/screens/dashboard/dashboard_overview.dart';

void main() {
  for (final width in [360.0, 1200.0]) {
    testWidgets('Dashboard fits $width and actions use the selected date', (
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
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      state.trainings.clear();
      state.trainings.add(
        TrainingSession(
          id: 'today',
          title: 'Today session',
          date: today,
          startTime: '09:00',
          endTime: '10:00',
          type: 'Gym',
          location: 'Training centre',
          coach: 'Coach',
          description: 'Session detail',
        ),
      );
      state.trainings.add(
        const TrainingSession(
          id: 'past',
          title: 'Past session',
          date: '2000-01-01',
          startTime: '09:00',
          endTime: '10:00',
          type: 'Gym',
          location: 'Training centre',
          coach: 'Coach',
          description: 'Past detail',
        ),
      );
      int? selectedTab;
      var backupOpened = false;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: DashboardOverview(
                state: state,
                onNavigateTab: (index) => selectedTab = index,
                onManageData: () => backupOpened = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (width >= 850) {
        final training = tester.getRect(
          find.byKey(const ValueKey('dashboard-panel-Training schedule')),
        );
        final valuations = tester.getRect(
          find.byKey(const ValueKey('dashboard-panel-Most valuable players')),
        );
        final availability = tester.getRect(
          find.byKey(const ValueKey('dashboard-panel-Squad availability')),
        );
        final contracts = tester.getRect(
          find.byKey(const ValueKey('dashboard-panel-Contract watch')),
        );
        expect(valuations.top - training.bottom, closeTo(20, 0.01));
        expect(contracts.top - availability.bottom, closeTo(20, 0.01));
        final campaigns = tester.getRect(
          find.byKey(const ValueKey('dashboard-panel-Partners & campaigns')),
        );
        // The current design lets each column flow at its natural height.
        final gridBottom = valuations.bottom > contracts.bottom
            ? valuations.bottom
            : contracts.bottom;
        expect(campaigns.top - gridBottom, closeTo(20, 0.01));
        expect(campaigns.top - valuations.bottom, greaterThanOrEqualTo(20));
        expect(campaigns.top - contracts.bottom, greaterThanOrEqualTo(20));
      }
      await tester.tap(find.text('Manage squad'));
      expect(selectedTab, 1);
      await tester.tap(find.text('Back up data'));
      expect(backupOpened, isTrue);
      await tester.ensureVisible(find.text('Today session'));
      await tester.pumpAndSettle();
      expect(find.text('Today session'), findsOneWidget);
      expect(find.text('Past session'), findsNothing);
      await tester.ensureVisible(find.text('First scheduled date'));
      await tester.tap(find.text('First scheduled date'));
      await tester.pumpAndSettle();
      expect(find.text('Past session'), findsOneWidget);
      expect(find.text('Today session'), findsNothing);
      await tester.ensureVisible(find.text('Manage commercial & sponsorship'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Manage commercial & sponsorship'));
      expect(selectedTab, 3);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    });
  }

  testWidgets('Dashboard supports an empty squad and calendar', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
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
    state.players.clear();
    state.trainings.clear();
    state.campaigns.clear();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: DashboardOverview(
            state: state,
            onNavigateTab: (_) {},
            onManageData: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final training = tester.getRect(
      find.byKey(const ValueKey('dashboard-panel-Training schedule')),
    );
    final valuations = tester.getRect(
      find.byKey(const ValueKey('dashboard-panel-Most valuable players')),
    );
    expect(valuations.top - training.bottom, closeTo(20, 0.01));
    expect(find.text('0 / 0'), findsOneWidget);
    expect(find.text('€0.0M'), findsOneWidget);
    await tester.ensureVisible(
      find.text('No sessions scheduled for this date.'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}
