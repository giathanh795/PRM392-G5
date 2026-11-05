import '../models/training_session.dart';

class TrainingScheduleData {
  static const year = 2026;
  static const months = [10, 11];
  static final List<TrainingSession> sessions = List.unmodifiable(_build());

  static List<TrainingSession> _build() {
    final result = <TrainingSession>[];
    for (final month in months) {
      final days = DateTime(year, month + 1, 0).day;
      for (var day = 1; day <= days; day++) {
        final date = DateTime(year, month, day);
        final dateKey =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        void add(
          String title,
          String start,
          String end,
          String type,
          String location,
          String coach,
          String description, [
          List<String> playerIds = const [],
        ]) {
          result.add(
            TrainingSession(
              id: 'training-$dateKey-${result.length}',
              title: title,
              date: dateKey,
              startTime: start,
              endTime: end,
              type: type,
              location: location,
              coach: coach,
              description: description,
              playerIds: List.unmodifiable(playerIds),
            ),
          );
        }

        switch (date.weekday) {
          case DateTime.monday:
            add(
              'Strength & conditioning',
              '09:00',
              '10:15',
              'Gym',
              'AXA Training Centre · Indoor gym',
              'Andreas Kornmayer',
              'Warm-up, core stability, lower-body strength and supervised hamstring injury-prevention exercises.',
            );
            add(
              'Pressing & transition drills',
              '11:00',
              '12:30',
              'Tactical',
              'AXA Training Centre · Pitch 1',
              'Andoni Iraola',
              'Small-sided games, coordinated pressing triggers and quick transitions from defence to attack.',
            );
          case DateTime.tuesday:
            add(
              'Goalkeeper handling & distribution',
              '09:00',
              '10:15',
              'Tactical',
              'AXA Training Centre · Goalkeeper area',
              'Goalkeeping coaching team',
              'Shot stopping, high-ball handling, one-on-one positioning and distribution under pressure.',
              ['p1', 'p2', 'p3', 'p4'],
            );
            add(
              'Finishing & attacking combinations',
              '11:00',
              '12:30',
              'Tactical',
              'AXA Training Centre · Pitch 2',
              'Andoni Iraola',
              'Passing combinations, movement between the lines and finishing from wide deliveries.',
              [
                'p12',
                'p13',
                'p14',
                'p15',
                'p16',
                'p17',
                'p18',
                'p19',
                'p20',
                'p21',
                'p22',
                'p23',
                'p24',
                'p25',
              ],
            );
          case DateTime.wednesday:
            add(
              'Recovery & mobility',
              '10:00',
              '11:00',
              'Recovery',
              'AXA Training Centre · Recovery suite',
              'Dr. Jonathan Power',
              'Low-intensity cycling, mobility work, stretching and supervised recovery. Individual loads are adjusted by the medical team.',
            );
          case DateTime.thursday:
            add(
              'Explosive power & sprint mechanics',
              '09:00',
              '10:15',
              'Gym',
              'AXA Training Centre · Performance gym',
              'Andreas Kornmayer',
              'Controlled acceleration, landing mechanics and short explosive strength blocks.',
            );
            add(
              'Defensive shape & set pieces',
              '11:00',
              '12:30',
              'Tactical',
              'AXA Training Centre · Pitch 1',
              'Andoni Iraola',
              'Defensive spacing, tracking runners and marking assignments at corners and free kicks.',
              [
                'p1',
                'p2',
                'p3',
                'p4',
                'p5',
                'p6',
                'p7',
                'p8',
                'p9',
                'p10',
                'p11',
              ],
            );
          case DateTime.friday:
            add(
              '11v11 match preparation',
              '10:00',
              '11:30',
              'Match Prep',
              'AXA Training Centre · Main pitch',
              'Andoni Iraola',
              'Team shape, build-up patterns, match scenarios and attacking and defensive set-piece rehearsal.',
            );
          case DateTime.saturday:
            add(
              'Technical sharpness & ball control',
              '09:30',
              '10:30',
              'Tactical',
              'AXA Training Centre · Pitch 2',
              'First-team coaching team',
              'Rondos, first-touch exercises and short passing combinations at controlled intensity.',
            );
            add(
              'Post-training recovery',
              '11:00',
              '11:45',
              'Recovery',
              'AXA Training Centre · Recovery suite',
              'Dr. Jonathan Power',
              'Guided cooldown, hydration review, mobility and recovery treatments.',
            );
          case DateTime.sunday:
            break;
        }
      }
    }
    return result;
  }
}
