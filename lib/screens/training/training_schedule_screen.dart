import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../../models/training_session.dart';

class TrainingScheduleScreen extends StatefulWidget {
  const TrainingScheduleScreen({super.key});

  @override
  State<TrainingScheduleScreen> createState() => _TrainingScheduleScreenState();
}

class _TrainingScheduleScreenState extends State<TrainingScheduleScreen> {
  int _selectedDayIndex = 0;

  final List<Map<String, dynamic>> _days = [
    {'day': 'MON', 'date': '12', 'fullDate': '2026-10-12'},
    {'day': 'TUE', 'date': '13', 'fullDate': '2026-10-13'},
    {'day': 'WED', 'date': '14', 'fullDate': '2026-10-14'},
    {'day': 'THU', 'date': '15', 'fullDate': '2026-10-15'},
    {'day': 'FRI', 'date': '16', 'fullDate': '2026-10-16'},
    {'day': 'SAT', 'date': '17', 'fullDate': '2026-10-17'},
    {'day': 'SUN', 'date': '18', 'fullDate': '2026-10-18'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final selectedDate = _days[_selectedDayIndex]['fullDate'] as String;

    final sessionsForDay = state.trainings
        .where((t) => t.date == selectedDate)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training & Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Schedule Session',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Training session modal ready for implementation')),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Calendar Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppTheme.bgCard,
            child: SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedDayIndex;
                  final day = _days[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    child: Container(
                      width: 58,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.lfcRed : AppTheme.bgCardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.lfcRed : AppTheme.borderSubtle,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day['day'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day['date'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date Header info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sessions for ${_days[_selectedDayIndex]['day']}, ${_days[_selectedDayIndex]['date']} Oct 2026',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${sessionsForDay.length} Planned',
                    style: const TextStyle(fontSize: 11, color: AppTheme.lfcYellow),
                  ),
                ),
              ],
            ),
          ),

          // Timeline Sessions List
          Expanded(
            child: sessionsForDay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No training scheduled for this date.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Add Rest Day or Activity', style: TextStyle(color: AppTheme.lfcRed)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: sessionsForDay.length,
                    itemBuilder: (context, index) {
                      final session = sessionsForDay[index];
                      return _buildSessionCard(session);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    Color typeColor;
    IconData icon;
    switch (session.type) {
      case 'Gym':
        typeColor = AppTheme.warning;
        icon = Icons.fitness_center;
        break;
      case 'Tactical':
        typeColor = AppTheme.lfcRed;
        icon = Icons.sports_soccer;
        break;
      case 'Recovery':
        typeColor = AppTheme.lfcTeal;
        icon = Icons.spa;
        break;
      default:
        typeColor = AppTheme.info;
        icon = Icons.timer;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session.startTime} - ${session.endTime} • ${session.type}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: session.status == 'In Progress'
                        ? AppTheme.lfcRed.withValues(alpha: 0.2)
                        : AppTheme.bgCardLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: session.status == 'In Progress' ? AppTheme.lfcRed : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    session.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: session.status == 'In Progress' ? AppTheme.lfcRed : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.borderSubtle, height: 24),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    session.location,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person_pin, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  session.coach,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.description,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
