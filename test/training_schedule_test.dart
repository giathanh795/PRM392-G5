import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liverpool_pms/core/theme/app_theme.dart';
import 'package:liverpool_pms/data/mock_data.dart';
import 'package:liverpool_pms/data/training_schedule_data.dart';
import 'package:liverpool_pms/providers/app_state_provider.dart';
import 'package:liverpool_pms/screens/training/training_schedule_screen.dart';

void main() {
  test(
    'Fixed programme covers October and November with valid groups and times',
    () {
      final sessions = TrainingScheduleData.sessions;
      final playerIds = MockData.players.map((p) => p.id).toSet();
      expect(sessions.map((s) => s.id).toSet().length, sessions.length);
      expect(sessions.any((s) => s.date == '2026-10-01'), isTrue);
      expect(sessions.any((s) => s.date == '2026-11-30'), isTrue);
      for (final session in sessions) {
        final date = DateTime.parse(session.date);
        expect(date.year, 2026);
        expect([10, 11], contains(date.month));
        expect(date.weekday, isNot(DateTime.sunday));
        expect(session.startTime.compareTo(session.endTime), lessThan(0));
        expect(playerIds.containsAll(session.playerIds), isTrue);
      }
      // No player is assigned to overlapping sessions on the same day.
      for (var i = 0; i < sessions.length; i++) {
        for (var j = i + 1; j < sessions.length; j++) {
          final a = sessions[i];
          final b = sessions[j];
          if (a.date != b.date) continue;
          final samePlayers =
              a.playerIds.isEmpty ||
              b.playerIds.isEmpty ||
              a.playerIds.any(b.playerIds.contains);
          if (samePlayers) {
            expect(
              a.endTime.compareTo(b.startTime) <= 0 ||
                  b.endTime.compareTo(a.startTime) <= 0,
              isTrue,
            );
          }
        }
      }
    },
  );

  for (final width in [360.0, 1200.0]) {
    testWidgets(
      'Training month limits, filters and session details at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
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
        state.setLanguage('en');
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: state,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const TrainingScheduleScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final october = find.byKey(const ValueKey('training-month-10'));
        await tester.ensureVisible(october);
        await tester.tap(october);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('training-previous-month')),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.byKey(const ValueKey('training-day-2026-09-30')),
          findsNothing,
        );
        final lastOctober = find.byKey(
          const ValueKey('training-day-2026-10-31'),
        );
        await tester.ensureVisible(lastOctober);
        await tester.tap(lastOctober);
        await tester.pumpAndSettle();
        final november = find.byKey(const ValueKey('training-month-11'));
        await tester.ensureVisible(november);
        await tester.tap(november);
        await tester.pumpAndSettle();
        expect(find.text('30 November 2026'), findsOneWidget);
        expect(
          tester
              .widget<IconButton>(
                find.byKey(const ValueKey('training-next-month')),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.byKey(const ValueKey('training-day-2026-12-01')),
          findsNothing,
        );
        final restDay = find.byKey(const ValueKey('training-day-2026-11-01'));
        await tester.ensureVisible(restDay);
        await tester.tap(restDay);
        await tester.pumpAndSettle();
        expect(find.text('Rest & recharge'), findsOneWidget);
        final nextDay = find.text('Find a training day');
        await tester.ensureVisible(nextDay);
        await tester.tap(nextDay);
        await tester.pumpAndSettle();
        expect(find.text('2 November 2026'), findsOneWidget);
        final tuesday = find.byKey(const ValueKey('training-day-2026-11-03'));
        await tester.ensureVisible(tuesday);
        await tester.tap(tuesday);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('All players'));
        await tester.tap(find.text('All players'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('#25 Giorgi Mamardashvili').last);
        await tester.pumpAndSettle();
        expect(find.text('Goalkeeper handling & distribution'), findsOneWidget);
        expect(find.text('Finishing & attacking combinations'), findsNothing);
        final gym = find.widgetWithText(ChoiceChip, 'Gym');
        await tester.ensureVisible(gym);
        await tester.tap(gym);
        await tester.pumpAndSettle();
        expect(find.text('No matching sessions'), findsOneWidget);
        await tester.ensureVisible(find.text('Clear filters'));
        await tester.tap(find.text('Clear filters'));
        await tester.pumpAndSettle();
        final details = find.text('View session & players').first;
        await tester.ensureVisible(details);
        await tester.tap(details);
        await tester.pumpAndSettle();
        expect(find.text('Participants (4)'), findsOneWidget);
        expect(find.text('Giorgi Mamardashvili'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        state.dispose();
      },
    );
  }
}
