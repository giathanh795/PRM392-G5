import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/training_schedule_data.dart';
import '../../models/player.dart';
import '../../models/training_session.dart';
import '../../providers/app_state_provider.dart';

class TrainingScheduleScreen extends StatefulWidget {
  const TrainingScheduleScreen({super.key});

  @override
  State<TrainingScheduleScreen> createState() => _TrainingScheduleScreenState();
}

class _TrainingScheduleScreenState extends State<TrainingScheduleScreen> {
  static const _types = ['All', 'Gym', 'Tactical', 'Recovery', 'Match Prep'];
  late DateTime _selectedDate;
  String _type = 'All';
  String? _playerId;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _selectedDate = _inRange(today)
        ? today
        : DateTime(TrainingScheduleData.year, 10, 1);
  }

  bool _inRange(DateTime date) =>
      date.year == TrainingScheduleData.year &&
      TrainingScheduleData.months.contains(date.month);
  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  List<TrainingSession> _filtered(List<TrainingSession> sessions) => sessions
      .where(
        (session) =>
            (_type == 'All' || session.type == _type) &&
            (_playerId == null ||
                session.playerIds.isEmpty ||
                session.playerIds.contains(_playerId)),
      )
      .toList();

  void _selectMonth(int month) => setState(() {
    final lastDay = DateTime(TrainingScheduleData.year, month + 1, 0).day;
    _selectedDate = DateTime(
      TrainingScheduleData.year,
      month,
      _selectedDate.day.clamp(1, lastDay),
    );
  });

  void _resetFilters() => setState(() {
    _type = 'All';
    _playerId = null;
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final playersByNumber = List<Player>.of(state.players)
      ..sort((a, b) {
        final numberOrder = a.number.compareTo(b.number);
        return numberOrder != 0 ? numberOrder : a.name.compareTo(b.name);
      });
    final allSessions =
        state.trainings.where((s) {
          final date = DateTime.tryParse(s.date);
          return date != null && _inRange(date);
        }).toList()..sort(
          (a, b) =>
              '${a.date} ${a.startTime}'.compareTo('${b.date} ${b.startTime}'),
        );
    final monthly = allSessions
        .where((s) => DateTime.parse(s.date).month == _selectedDate.month)
        .toList();
    final daySessions = monthly
        .where((s) => s.date == _dateKey(_selectedDate))
        .toList();
    final filtered = _filtered(monthly);
    final selected = _filtered(daySessions);
    final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final trainingDays = monthly.map((s) => s.date).toSet().length;
    final minutes = monthly.fold(
      0,
      (sum, s) => sum + _minutes(s.endTime) - _minutes(s.startTime),
    );
    final today = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Training & Schedule')),
      body: SingleChildScrollView(
        key: const PageStorageKey('training-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppTheme.surfaceNavyLight, AppTheme.surfaceNavy],
                    ),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tag('FIRST TEAM · OCT – NOV 2026', AppTheme.accentCyan),
                      const SizedBox(height: 12),
                      const Text(
                        'Train with a plan.',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Explore the squad programme, individual groups and daily training details.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fixed training programme · Sundays are rest days',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 700 ? 3 : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 10) / columns;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          [
                                _summary(
                                  'Sessions this month',
                                  '${monthly.length}',
                                  Icons.event_note,
                                  AppTheme.info,
                                ),
                                _summary(
                                  'Training / rest days',
                                  '$trainingDays / ${days - trainingDays}',
                                  Icons.calendar_month,
                                  AppTheme.success,
                                ),
                                _summary(
                                  'Planned training hours',
                                  (minutes / 60).toStringAsFixed(1),
                                  Icons.timer_outlined,
                                  AppTheme.lfcYellow,
                                ),
                              ]
                              .map(
                                (child) => SizedBox(width: width, child: child),
                              )
                              .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _surface(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Find your sessions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _types
                            .map(
                              (type) => ChoiceChip(
                                label: Text(type),
                                selected: _type == type,
                                onSelected: (_) => setState(() => _type = type),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 380,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'training-player-${_playerId ?? 'all'}-${state.players.length}',
                          ),
                          initialValue:
                              state.players.any((p) => p.id == _playerId)
                              ? _playerId
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Player',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All players'),
                            ),
                            ...playersByNumber.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '#${p.number} ${p.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (id) => setState(() => _playerId = id),
                        ),
                      ),
                      if (_type != 'All' || _playerId != null)
                        TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(
                            Icons.filter_alt_off_outlined,
                            size: 18,
                          ),
                          label: const Text('Reset filters'),
                        ),
                      const SizedBox(height: 10),
                      const Text(
                        'Calendar markers show sessions matching your filters. Monthly totals show the full programme.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final calendar = _calendar(filtered, monthly, today);
                    final agenda = _agenda(
                      selected,
                      daySessions,
                      state.players,
                    );
                    if (constraints.maxWidth < 900) {
                      return Column(
                        children: [
                          calendar,
                          const SizedBox(height: 20),
                          agenda,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 420, child: calendar),
                        const SizedBox(width: 20),
                        Expanded(child: agenda),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendar(
    List<TrainingSession> filtered,
    List<TrainingSession> monthly,
    DateTime today,
  ) {
    final first = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final leading = first.weekday - 1;
    final days = DateTime(first.year, first.month + 1, 0).day;
    final cells = ((leading + days) / 7).ceil() * 7;
    return _surface(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final month in TrainingScheduleData.months)
                ChoiceChip(
                  key: ValueKey('training-month-$month'),
                  label: Text(DateFormat('MMMM').format(DateTime(2026, month))),
                  selected: _selectedDate.month == month,
                  onSelected: (_) => _selectMonth(month),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(first),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('training-previous-month'),
                tooltip: 'Previous month',
                onPressed: first.month == 10 ? null : () => _selectMonth(10),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                key: const ValueKey('training-next-month'),
                tooltip: 'Next month',
                onPressed: first.month == 11 ? null : () => _selectMonth(11),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          if (_inRange(today))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedDate = today),
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Today'),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 6,
              childAspectRatio: 0.9,
            ),
            itemCount: cells,
            itemBuilder: (context, index) {
              final day = index - leading + 1;
              if (day < 1 || day > days) return const SizedBox.shrink();
              final date = DateTime(first.year, first.month, day);
              final key = _dateKey(date);
              final count = filtered.where((s) => s.date == key).length;
              final isRest = !monthly.any((s) => s.date == key);
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              return Semantics(
                selected: isSelected,
                button: true,
                label:
                    '${DateFormat('MMMM d, yyyy').format(date)}, $count matching sessions${isRest ? ', rest day' : ''}',
                child: Tooltip(
                  message: isRest ? 'Rest day' : '$count matching sessions',
                  child: Material(
                    color: isSelected
                        ? AppTheme.accentBlue
                        : AppTheme.primaryNavy,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      key: ValueKey('training-day-$key'),
                      onTap: () => setState(() => _selectedDate = date),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: DateUtils.isSameDay(date, today)
                                ? AppTheme.accentCyan
                                : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isRest
                                  ? '–'
                                  : count == 0
                                  ? '·'
                                  : '$count',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white
                                    : count > 0
                                    ? AppTheme.accentCyan
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Number = matching sessions   ·   – = rest day',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Available dates: 1 October – 30 November 2026',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _agenda(
    List<TrainingSession> sessions,
    List<TrainingSession> unfiltered,
    List<Player> players,
  ) => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tag(
          DateFormat('EEEE').format(_selectedDate).toUpperCase(),
          AppTheme.accentCyan,
        ),
        const SizedBox(height: 10),
        Text(
          DateFormat('d MMMM yyyy').format(_selectedDate),
          key: const ValueKey('training-selected-date'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '${sessions.length} sessions${_type != 'All' || _playerId != null ? ' matching filters' : ' planned'}',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 18),
        if (sessions.isEmpty) ...[
          Icon(
            unfiltered.isEmpty ? Icons.spa_outlined : Icons.search_off,
            size: 40,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            unfiltered.isEmpty ? 'Rest & recharge' : 'No matching sessions',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            unfiltered.isEmpty
                ? 'No team training is planned for this date. Take time to recover before the next training day.'
                : 'Try another training type or player to see more sessions.',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (unfiltered.isNotEmpty)
            OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Clear filters'),
            ),
          if (unfiltered.isEmpty)
            OutlinedButton.icon(
              onPressed: _nextTrainingDay,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Find a training day'),
            ),
        ] else
          ...sessions.map((session) => _sessionCard(session, players)),
      ],
    ),
  );

  void _nextTrainingDay() {
    final sessions = _filtered(context.read<AppStateProvider>().trainings);
    final dates =
        sessions
            .map((s) => DateTime.tryParse(s.date))
            .whereType<DateTime>()
            .where(_inRange)
            .toSet()
            .toList()
          ..sort();
    if (dates.isEmpty) {
      _resetFilters();
      return;
    }
    final next =
        dates.where((d) => d.isAfter(_selectedDate)).firstOrNull ?? dates.first;
    setState(() => _selectedDate = next);
  }

  Widget _sessionCard(TrainingSession session, List<Player> players) {
    final color = _color(session.type);
    final participants = _participants(session, players);
    return Container(
      key: ValueKey('training-session-${session.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tag(session.type, color),
              _tag('Planned', AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${session.startTime} – ${session.endTime}  ·  ${_minutes(session.endTime) - _minutes(session.startTime)} min',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            session.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _info(Icons.location_on_outlined, session.location),
          _info(Icons.person_outline, session.coach),
          _info(
            Icons.groups_outlined,
            '${session.playerIds.isEmpty ? 'Full squad' : 'Selected group'} · ${participants.length} players',
          ),
          const SizedBox(height: 8),
          Text(
            session.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showSession(session, participants),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View session & players'),
          ),
        ],
      ),
    );
  }

  List<Player> _participants(TrainingSession session, List<Player> players) =>
      players
          .where(
            (p) =>
                session.playerIds.isEmpty || session.playerIds.contains(p.id),
          )
          .toList();

  void _showSession(TrainingSession session, List<Player> participants) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          constraints: const BoxConstraints(maxWidth: 620),
          scrollable: true,
          title: Text(session.title),
          content: SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tag(session.type, _color(session.type)),
                const SizedBox(height: 16),
                _info(
                  Icons.calendar_today_outlined,
                  '${session.date} · ${session.startTime} – ${session.endTime}',
                ),
                _info(Icons.location_on_outlined, session.location),
                _info(Icons.person_outline, session.coach),
                const SizedBox(height: 12),
                Text(session.description, style: const TextStyle(height: 1.6)),
                const Divider(height: 30, color: AppTheme.borderSubtle),
                Text(
                  'Participants (${participants.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (participants.isEmpty)
                  const Text('No players available for this group.'),
                ...participants.map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.surfaceNavyLight,
                      child: Text(
                        '${p.number}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text(p.positionName),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );

  Widget _surface(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.surfaceNavy,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.borderSubtle),
    ),
    child: child,
  );

  Widget _summary(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceNavy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _info(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Color _color(String type) => switch (type) {
    'Gym' => AppTheme.warning,
    'Tactical' => AppTheme.info,
    'Recovery' => AppTheme.accentCyan,
    _ => AppTheme.lfcRed,
  };
  int _minutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
