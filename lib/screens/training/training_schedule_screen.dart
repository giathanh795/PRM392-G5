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

  // Hộp thoại tạo buổi tập mới
  void _showAddSessionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final locationController = TextEditingController(text: 'AXA Training Ground - Pitch 1');
    final coachController = TextEditingController(text: 'Andoni Iraola');
    final descController = TextEditingController();
    final startController = TextEditingController(text: '10:00');
    final endController = TextEditingController(text: '12:00');

    String selectedType = 'Tactical';
    String selectedIntensity = 'High Intensity';
    final selectedPlayers = <String>{};

    final allPlayers = context.read<AppStateProvider>().players;
    final currentDate = _days[_selectedDayIndex]['fullDate'] as String;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_task, color: AppTheme.accentCyan, size: 22),
              SizedBox(width: 8),
              Text('Lên Lịch Tập Huấn AXA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      labelText: 'Tiêu đề buổi tập',
                      hintText: 'Ví dụ: Pressing cường độ cao & Phối hợp nhanh',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startController,
                          decoration: const InputDecoration(labelText: 'Bắt đầu', hintText: '10:00'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(labelText: 'Kết thúc', hintText: '12:00'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Chuyên đề giáo án:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['Tactical', 'Gym', 'Recovery', 'Set-Piece', 'Match Prep'].map((t) {
                      final isSel = selectedType == t;
                      return ChoiceChip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: AppTheme.accentBlue,
                        onSelected: (_) => setDialogState(() => selectedType = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Mức độ tải trọng (Intensity):', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['Light', 'Moderate', 'High Intensity'].map((intense) {
                      final isSel = selectedIntensity == intense;
                      Color c = AppTheme.success;
                      if (intense == 'High Intensity') c = AppTheme.lfcRed;
                      if (intense == 'Moderate') c = AppTheme.warning;
                      return ChoiceChip(
                        label: Text(intense, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: c.withValues(alpha: 0.3),
                        onSelected: (_) => setDialogState(() => selectedIntensity = intense),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Địa điểm sân tập'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: coachController,
                    decoration: const InputDecoration(labelText: 'HLV phụ trách'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Mục tiêu & Hướng dẫn'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phân công cầu thủ (${selectedPlayers.length}/${allPlayers.length}):',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            if (selectedPlayers.length == allPlayers.length) {
                              selectedPlayers.clear();
                            } else {
                              selectedPlayers.addAll(allPlayers.map((p) => p.id));
                            }
                          });
                        },
                        child: Text(
                          selectedPlayers.length == allPlayers.length ? 'Bỏ chọn' : 'Chọn tất cả',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allPlayers.map((p) {
                      final isSel = selectedPlayers.contains(p.id);
                      final isInjured = p.status == 'Injured';
                      return FilterChip(
                        selected: isSel,
                        label: Text(
                          '#${p.number} ${p.name.split(' ').last}${isInjured ? ' ⚠️' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isInjured ? AppTheme.danger : (isSel ? Colors.white : AppTheme.textSecondary),
                          ),
                        ),
                        backgroundColor: AppTheme.surfaceNavyLight,
                        selectedColor: AppTheme.accentBlue,
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
              child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tiêu đề buổi tập!')),
                  );
                  return;
                }

                final newSession = TrainingSession(
                  id: 'train_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  date: currentDate,
                  startTime: startController.text.trim(),
                  endTime: endController.text.trim(),
                  type: selectedType,
                  location: locationController.text.trim(),
                  coach: coachController.text.trim(),
                  description: descController.text.trim(),
                  intensity: selectedIntensity,
                  status: 'Upcoming',
                  playerIds: selectedPlayers.toList(),
                );

                await context.read<AppStateProvider>().addTrainingSession(newSession);
                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã xếp lịch buổi tập: $title cho ngày $currentDate!')),
                  );
                }
              },
              child: const Text('Lên lịch'),
            ),
          ],
        ),
      ),
    );
  }

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
            icon: const Icon(Icons.add_task, color: AppTheme.accentCyan),
            tooltip: 'Lên lịch buổi tập mới',
            onPressed: () => _showAddSessionDialog(context),
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

          // Day Info & Add Button Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch tập luyện: ${_days[_selectedDayIndex]['day']}, ${_days[_selectedDayIndex]['fullDate']}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sessionsForDay.length} buổi tập tại AXA Training Centre',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lfcRed,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm buổi tập', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showAddSessionDialog(context),
                ),
              ],
            ),
          ),

          // List of Training Sessions for the Selected Day
          Expanded(
            child: sessionsForDay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available, size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Ngày nghỉ hồi phục thể lực (Rest / Recovery Day)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Không có lịch tập nào được xếp cho ngày này.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentCyan),
                          icon: const Icon(Icons.add),
                          label: const Text('Xếp lịch tập ngay'),
                          onPressed: () => _showAddSessionDialog(context),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sessionsForDay.length,
                    itemBuilder: (context, index) {
                      final session = sessionsForDay[index];
                      return _buildSessionCard(context, session);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, TrainingSession session) {
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
      case 'Set-Piece':
        typeColor = AppTheme.accentCyan;
        icon = Icons.flag;
        break;
      default:
        typeColor = AppTheme.info;
        icon = Icons.timer;
    }

    final isCompleted = session.status == 'Completed';

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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session.startTime} - ${session.endTime} • ${session.type} • ${session.intensity}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.success.withValues(alpha: 0.2)
                        : (session.status == 'In Progress' ? AppTheme.lfcRed.withValues(alpha: 0.2) : AppTheme.bgCardLight),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted
                          ? AppTheme.success
                          : (session.status == 'In Progress' ? AppTheme.lfcRed : AppTheme.borderSubtle),
                    ),
                  ),
                  child: Text(
                    session.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppTheme.success
                          : (session.status == 'In Progress' ? AppTheme.lfcRed : AppTheme.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.borderSubtle, height: 20),
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
            if (session.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                session.description,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.playerIds.isEmpty
                      ? 'Tất cả đội 1 tham gia'
                      : 'Đã phân công ${session.playerIds.length} cầu thủ',
                  style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                      tooltip: 'Xóa buổi tập',
                      onPressed: () {
                        context.read<AppStateProvider>().deleteTrainingSession(session.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa buổi tập')),
                        );
                      },
                    ),
                    if (!isCompleted)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 14),
                        label: const Text('Hoàn thành', style: TextStyle(fontSize: 11)),
                        onPressed: () async {
                          await context.read<AppStateProvider>().completeTrainingSession(session.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã hoàn thành giáo án & tự động tăng thể lực cho cầu thủ!')),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
