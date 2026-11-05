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

  // Hộp thoại tạo buổi tập mới
  void _showAddSessionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final locationController = TextEditingController(
      text: 'AXA Training Ground - Pitch 1',
    );
    final coachController = TextEditingController(text: 'Andoni Iraola');
    final descController = TextEditingController();
    final startController = TextEditingController(text: '10:00');
    final endController = TextEditingController(text: '12:00');

    String selectedType = 'Tactical';
    final selectedPlayers = <String>{};

    final allPlayers = context.read<AppStateProvider>().players;
    final currentDateStr = _dateKey(_selectedDate);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_task, color: AppTheme.accentCyan, size: 22),
              const SizedBox(width: 8),
              Text(
                'Schedule training ($currentDateStr)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Session title',
                      hintText: 'Example: High-intensity pressing and quick combinations',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startController,
                          decoration: const InputDecoration(
                            labelText: 'Start time',
                            hintText: '10:00',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(
                            labelText: 'End time',
                            hintText: '12:00',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Training type:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['Tactical', 'Gym', 'Recovery', 'Match Prep'].map(
                      (t) {
                        final isSel = selectedType == t;
                        return ChoiceChip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          selectedColor: _color(t),
                          onSelected: (_) =>
                              setDialogState(() => selectedType = t),
                        );
                      },
                    ).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Training location',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: coachController,
                    decoration: const InputDecoration(labelText: 'Coach'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Objectives & instructions',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assign players (${selectedPlayers.length}/${allPlayers.length}):',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            if (selectedPlayers.length == allPlayers.length) {
                              selectedPlayers.clear();
                            } else {
                              selectedPlayers.addAll(
                                allPlayers.map((p) => p.id),
                              );
                            }
                          });
                        },
                        child: Text(
                          selectedPlayers.length == allPlayers.length
                              ? 'Clear selection'
                              : 'Select all',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allPlayers.map((p) {
                      final isSel = selectedPlayers.contains(p.id);
                      return FilterChip(
                        label: Text(
                          '#${p.number} ${p.name.split(' ').last}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: isSel,
                        selectedColor: AppTheme.accentCyan.withValues(
                          alpha: 0.25,
                        ),
                        checkmarkColor: AppTheme.accentCyan,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedPlayers.add(p.id);
                            } else {
                              selectedPlayers.remove(p.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                final newSession = TrainingSession(
                  id: 'session-${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  date: currentDateStr,
                  startTime: startController.text.trim(),
                  endTime: endController.text.trim(),
                  type: selectedType,
                  location: locationController.text.trim(),
                  coach: coachController.text.trim(),
                  description: descController.text.trim().isNotEmpty
                      ? descController.text.trim()
                      : 'Training programme at AXA Training Ground.',
                  playerIds: selectedPlayers.toList(),
                );

                context.read<AppStateProvider>().addTrainingSession(newSession);
                Navigator.of(dialogCtx).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added session "$title" on $currentDateStr!'),
                  ),
                );
              },
              child: const Text(
                'Create session',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final trainingDays = monthly.map((s) => s.date).toSet().length;
    final minutes = monthly.fold(
      0,
      (sum, s) => sum + _minutes(s.endTime) - _minutes(s.startTime),
    );
    final today = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training & Schedule'),
        actions: [
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: state.isDarkMode ? AppTheme.accentGold : Colors.amber.shade700,
            ),
            tooltip: state.isDarkMode
                ? 'Chuyển sang Giao diện Sáng'
                : 'Chuyển sang Giao diện Tối',
            onPressed: () => context.read<AppStateProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.add_task, color: AppTheme.accentCyan),
            tooltip: 'Create training session',
            onPressed: () => _showAddSessionDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentCyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_task),
        label: const Text(
          'Schedule training',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddSessionDialog(context),
      ),
      body: SingleChildScrollView(
        key: const PageStorageKey('training-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
                        'AXA Training Programme',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage first-team training, tactical preparation, conditioning and recovery.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(Icons.add_task, size: 18),
                            label: const Text(
                              'Schedule for this date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _showAddSessionDialog(context),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final today = DateUtils.dateOnly(DateTime.now());
                              if (_inRange(today)) {
                                setState(() => _selectedDate = today);
                              } else {
                                setState(
                                  () => _selectedDate = DateTime(
                                    TrainingScheduleData.year,
                                    10,
                                    1,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.today, size: 18),
                            label: const Text('Today'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 720
                        ? (constraints.maxWidth - 24) / 3
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: _summary(
                            'Sessions in ${DateFormat('MMMM').format(_selectedDate)}',
                            '${monthly.length}',
                            Icons.calendar_month,
                            AppTheme.info,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _summary(
                            'Training days',
                            '$trainingDays',
                            Icons.event_available,
                            AppTheme.success,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _summary(
                            'Programme minutes',
                            '$minutes',
                            Icons.timer_outlined,
                            AppTheme.accentCyan,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _surface(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter training calendar',
                        style: TextStyle(
                          fontSize: 16,
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
                                selectedColor: _color(type),
                                onSelected: (_) => setState(() => _type = type),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _playerId,
                          isExpanded: true,
                          hint: const Text('Filter by participating player'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All players'),
                            ),
                            ...playersByNumber.map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '#${p.number} ${p.name}',
                                  maxLines: 1,
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
                        'Calendar markers show sessions matching your filters.',
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
    final isCompleted = session.status == 'Completed';

    return Container(
      key: ValueKey('training-session-${session.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: isCompleted ? AppTheme.success : color,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tag(session.type, color),
                    _tag(
                      isCompleted ? 'Completed' : 'Planned',
                      isCompleted ? AppTheme.success : AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.danger,
                ),
                tooltip: 'Delete session',
                onPressed: () {
                  context.read<AppStateProvider>().deleteTrainingSession(
                    session.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session removed from the schedule!'),
                    ),
                  );
                },
              ),
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
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showSession(session, participants),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('View session & players'),
              ),
              if (!isCompleted)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text(
                    'Complete session',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await context
                        .read<AppStateProvider>()
                        .completeTrainingSession(session.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Session completed and participant fitness updated!',
                        ),
                      ),
                    );
                  },
                ),
            ],
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
