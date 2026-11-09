import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/training_schedule_data.dart';
import '../../models/player.dart';
import '../../models/training_session.dart';
import '../../providers/app_state_provider.dart';
import '../player/player_detail_screen.dart';
import '../../widgets/language_toggle_button.dart';

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

  String _typeName(String type, bool isVi) {
    if (!isVi) return type;
    switch (type.toLowerCase()) {
      case 'all':
        return 'Tất cả';
      case 'gym':
        return 'Thể lực';
      case 'tactical':
        return 'Chiến thuật';
      case 'recovery':
        return 'Phục hồi';
      case 'match prep':
        return 'Chuẩn bị thi đấu';
      default:
        return type;
    }
  }

  String _weekdayName(int weekday, bool isVi) {
    if (!isVi) {
      const enDays = ['', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
      return (weekday >= 1 && weekday <= 7) ? enDays[weekday] : '';
    }
    const viDays = ['', 'THỨ HAI', 'THỨ BA', 'THỨ TƯ', 'THỨ NĂM', 'THỨ SÁU', 'THỨ BẢY', 'CHỦ NHẬT'];
    return (weekday >= 1 && weekday <= 7) ? viDays[weekday] : '';
  }

  String _monthName(int month, bool isVi) {
    if (!isVi) return DateFormat('MMMM').format(DateTime(2026, month));
    return 'Tháng $month';
  }

  void _showAddSessionDialog(BuildContext parentContext) {
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

    final allPlayers = parentContext.read<AppStateProvider>().players;
    final currentDateStr = _dateKey(_selectedDate);

    showDialog(
      context: parentContext,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogStateCtx, setDialogState) => AlertDialog(
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

                Navigator.of(dialogCtx).pop();
                parentContext.read<AppStateProvider>().addTrainingSession(newSession);

                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Added session "$title" on $currentDateStr!'),
                    ),
                  );
                }
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

    final isVi = state.isVietnamese;
    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Kế hoạch Huấn luyện AXA' : 'Training & Schedule'),
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: state.isDarkMode ? AppTheme.accentGold : Colors.amber.shade700,
            ),
            tooltip: state.isDarkMode
                ? (isVi ? 'Chuyển sang Giao diện Sáng' : 'Switch to Light Mode')
                : (isVi ? 'Chuyển sang Giao diện Tối' : 'Switch to Dark Mode'),
            onPressed: () => context.read<AppStateProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.add_task, color: AppTheme.accentCyan),
            tooltip: isVi ? 'Tạo buổi tập mới' : 'Create training session',
            onPressed: () => _showAddSessionDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentCyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_task),
        label: Text(
          isVi ? 'Lên lịch tập luyện' : 'Schedule training',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                      _tag(
                        isVi ? 'ĐỘI 1 · THÁNG 10 – 11/2026' : 'FIRST TEAM · OCT – NOV 2026',
                        AppTheme.accentCyan,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isVi ? 'Chương trình Huấn luyện AXA' : 'AXA Training Programme',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isVi
                            ? 'Quản lý huấn luyện đội 1, chuẩn bị chiến thuật, thể lực và phục hồi thể trạng.'
                            : 'Manage first-team training, tactical preparation, conditioning and recovery.',
                        style: const TextStyle(
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
                            label: Text(
                              isVi ? 'Lên lịch cho ngày này' : 'Schedule for this date',
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
                            label: Text(isVi ? 'Hôm nay' : 'Today'),
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
                            isVi
                                ? 'Buổi tập trong tháng ${_selectedDate.month}'
                                : 'Sessions in ${DateFormat('MMMM').format(_selectedDate)}',
                            '${monthly.length}',
                            Icons.calendar_month,
                            AppTheme.info,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _summary(
                            isVi ? 'Ngày tập luyện' : 'Training days',
                            '$trainingDays',
                            Icons.event_available,
                            AppTheme.success,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _summary(
                            isVi ? 'Phút giáo án' : 'Programme minutes',
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
                      Text(
                        isVi ? 'Bộ lọc lịch tập luyện' : 'Filter training calendar',
                        style: const TextStyle(
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
                                label: Text(_typeName(type, isVi)),
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
                          hint: Text(
                            isVi ? 'Lọc theo cầu thủ tham gia' : 'Filter by participating player',
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(isVi ? 'Tất cả cầu thủ' : 'All players'),
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
                          label: Text(isVi ? 'Đặt lại bộ lọc' : 'Reset filters'),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        isVi
                            ? 'Dấu chấm trên lịch thể hiện các buổi tập khớp với bộ lọc của bạn.'
                            : 'Calendar markers show sessions matching your filters.',
                        style: const TextStyle(
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
                    final calendar = _calendar(filtered, monthly, today, isVi);
                    final agenda = _agenda(
                      selected,
                      daySessions,
                      state.players,
                      isVi,
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
    bool isVi,
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
                  label: Text(_monthName(month, isVi)),
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
                  isVi
                      ? 'Tháng ${first.month}, ${first.year}'
                      : DateFormat('MMMM yyyy').format(first),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('training-previous-month'),
                tooltip: isVi ? 'Tháng trước' : 'Previous month',
                onPressed: first.month == 10 ? null : () => _selectMonth(10),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                key: const ValueKey('training-next-month'),
                tooltip: isVi ? 'Tháng sau' : 'Next month',
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
                label: Text(isVi ? 'Hôm nay' : 'Today'),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: (isVi
                    ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                    : ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
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
                  message: isRest
                      ? (isVi ? 'Ngày nghỉ hồi phục' : 'Rest day')
                      : (isVi ? '$count buổi tập khớp' : '$count matching sessions'),
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
          Text(
            isVi
                ? 'Số = số buổi tập khớp bộ lọc   ·   – = ngày nghỉ hồi phục'
                : 'Number = matching sessions   ·   – = rest day',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            isVi
                ? 'Khoảng thời gian: 1/10 – 30/11/2026'
                : 'Available dates: 1 October – 30 November 2026',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _agenda(
    List<TrainingSession> sessions,
    List<TrainingSession> unfiltered,
    List<Player> players,
    bool isVi,
  ) => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tag(
          _weekdayName(_selectedDate.weekday, isVi),
          AppTheme.accentCyan,
        ),
        const SizedBox(height: 10),
        Text(
          isVi
              ? '${_selectedDate.day} ${_monthName(_selectedDate.month, true)} ${_selectedDate.year}'
              : DateFormat('d MMMM yyyy').format(_selectedDate),
          key: const ValueKey('training-selected-date'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isVi
              ? '${sessions.length} buổi tập ${_type != 'All' || _playerId != null ? 'khớp bộ lọc' : 'theo kế hoạch'}'
              : '${sessions.length} sessions${_type != 'All' || _playerId != null ? ' matching filters' : ' planned'}',
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
            unfiltered.isEmpty
                ? (isVi ? 'Nghỉ ngơi & Hồi phục' : 'Rest & recharge')
                : (isVi ? 'Không có buổi tập phù hợp' : 'No matching sessions'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            unfiltered.isEmpty
                ? (isVi
                    ? 'Không có lịch tập nào cho ngày này. Hãy dành thời gian hồi phục thể lực trước buổi tập kế tiếp.'
                    : 'No team training is planned for this date. Take time to recover before the next training day.')
                : (isVi
                    ? 'Hãy thử đổi bộ lọc bài tập hoặc chọn cầu thủ khác để xem thêm buổi tập.'
                    : 'Try another training type or player to see more sessions.'),
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (unfiltered.isNotEmpty)
            OutlinedButton(
              onPressed: _resetFilters,
              child: Text(isVi ? 'Xóa bộ lọc' : 'Clear filters'),
            ),
          if (unfiltered.isEmpty)
            OutlinedButton.icon(
              onPressed: _nextTrainingDay,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(isVi ? 'Tìm ngày có lịch tập' : 'Find a training day'),
            ),
        ] else
          ...sessions.map((session) => _sessionCard(session, players, isVi)),
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

  Widget _sessionCard(TrainingSession session, List<Player> players, bool isVi) {
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
                    _tag(_typeName(session.type, isVi), color),
                    _tag(
                      isCompleted
                          ? (isVi ? 'Đã hoàn thành' : 'Completed')
                          : (isVi ? 'Đã lên lịch' : 'Planned'),
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
                tooltip: isVi ? 'Xóa buổi tập' : 'Delete session',
                onPressed: () {
                  context.read<AppStateProvider>().deleteTrainingSession(
                    session.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isVi
                            ? 'Đã xóa buổi tập khỏi kế hoạch!'
                            : 'Session removed from the schedule!',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${session.startTime} – ${session.endTime}  ·  ${_minutes(session.endTime) - _minutes(session.startTime)} ${isVi ? 'phút' : 'min'}',
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
            isVi
                ? '${session.playerIds.isEmpty ? 'Toàn đội 1' : 'Nhóm chỉ định'} · ${participants.length} cầu thủ'
                : '${session.playerIds.isEmpty ? 'Full squad' : 'Selected group'} · ${participants.length} players',
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
                onPressed: () => _showSession(session, participants, isVi),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(
                  isVi ? 'Xem chi tiết & danh sách' : 'View session & players',
                ),
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
                  label: Text(
                    isVi ? 'Hoàn thành buổi tập' : 'Complete session',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    await context
                        .read<AppStateProvider>()
                        .completeTrainingSession(session.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isVi
                              ? 'Đã hoàn thành buổi tập & cập nhật thể lực cầu thủ!'
                              : 'Session completed and participant fitness updated!',
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

  void _showSession(
    TrainingSession session,
    List<Player> participants,
    bool isVi,
  ) =>
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
                _tag(_typeName(session.type, isVi), _color(session.type)),
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
                  isVi
                      ? 'Danh sách tham gia (${participants.length})'
                      : 'Participants (${participants.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (participants.isEmpty)
                  Text(
                    isVi
                        ? 'Chưa có cầu thủ nào trong nhóm này.'
                        : 'No players available for this group.',
                  ),
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
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(p.positionName, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerDetailScreen(player: p),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isVi ? 'Đóng' : 'Close'),
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
