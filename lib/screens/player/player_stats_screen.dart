import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/radar_chart_widget.dart';
import '../../widgets/stat_progress_bar.dart';
import 'package:fl_chart/fl_chart.dart';

class PlayerStatsScreen extends StatefulWidget {
  final Player player;

  const PlayerStatsScreen({super.key, required this.player});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  late Set<String> _selectedAttributes;
  final List<Color> _chartColors = [
    AppTheme.lfcRed,
    AppTheme.lfcYellow,
    AppTheme.info,
    AppTheme.success,
    Colors.purpleAccent,
    Colors.orangeAccent,
  ];

  @override
  void initState() {
    super.initState();
    final keys = widget.player.latestAttributes.keys.toList();
    _selectedAttributes = keys.take(2).toSet();
  }

  // Hộp thoại chỉnh sửa chi tiết các chỉ số bằng Slider (40 -> 99)
  void _showEditStatsDialog(BuildContext context, Player currentPlayer) {
    final currentStats = Map<String, double>.from(currentPlayer.latestAttributes);

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
              const Icon(Icons.tune, color: AppTheme.accentCyan, size: 22),
              const SizedBox(width: 8),
              Text(
                'Điều chỉnh chỉ số: ${currentPlayer.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bộ chỉ số tối ưu cho vị trí ${currentPlayer.positionName}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                ...currentStats.keys.map((attr) {
                  final val = currentStats[attr] ?? 70.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(attr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceNavyLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              val.toInt().toString(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: val,
                        min: 40.0,
                        max: 99.0,
                        divisions: 59,
                        activeColor: AppTheme.accentCyan,
                        inactiveColor: AppTheme.borderSubtle,
                        onChanged: (newVal) {
                          setDialogState(() {
                            currentStats[attr] = newVal;
                          });
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                  );
                }),
              ],
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
                // Cập nhật lại chỉ số mới vào Progress History
                final updatedHist = List<PlayerStatistic>.from(currentPlayer.progressHistory);
                if (updatedHist.isNotEmpty) {
                  updatedHist[updatedHist.length - 1] = PlayerStatistic(
                    date: updatedHist.last.date,
                    attributes: currentStats,
                  );
                } else {
                  updatedHist.add(PlayerStatistic(date: 'Now', attributes: currentStats));
                }

                final updated = currentPlayer.copyWith(progressHistory: updatedHist);
                await context.read<AppStateProvider>().updatePlayer(updated);

                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật chỉ số kỹ thuật cho ${currentPlayer.name}!')),
                  );
                }
              },
              child: const Text('Lưu chỉ số'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final currentPlayer = state.players.firstWhere(
      (p) => p.id == widget.player.id,
      orElse: () => widget.player,
    );

    final attributes = currentPlayer.latestAttributes;
    final allAttrKeys = attributes.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${currentPlayer.name} - Stats & Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.accentCyan),
            tooltip: 'Chỉnh sửa chỉ số kỹ thuật',
            onPressed: () => _showEditStatsDialog(context, currentPlayer),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 14, color: AppTheme.lfcYellow),
                const SizedBox(width: 4),
                Text(
                  currentPlayer.positionName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Position Notice Banner với Nút Điều chỉnh chỉ số
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lfcRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lfcRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.lfcRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Position-Adaptive Metrics: Bộ chỉ số được tự động cấu hình cho vị trí ${currentPlayer.position.name.toUpperCase()}.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentCyan,
                      side: const BorderSide(color: AppTheme.accentCyan),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.tune, size: 14),
                    label: const Text('Sửa', style: TextStyle(fontSize: 11)),
                    onPressed: () => _showEditStatsDialog(context, currentPlayer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 1. Radar View & Bar Metrics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Radar Attributes Overview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 14, color: AppTheme.accentCyan),
                          label: const Text('Chỉnh sửa', style: TextStyle(color: AppTheme.accentCyan, fontSize: 12)),
                          onPressed: () => _showEditStatsDialog(context, currentPlayer),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 260,
                      width: double.infinity,
                      child: RadarChartWidget(
                        attributes: attributes,
                        fillColor: AppTheme.accentCyan.withValues(alpha: 0.25),
                        lineColor: AppTheme.accentCyan,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Individual Skill Metrics',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ...attributes.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: StatProgressBar(
                            label: e.key,
                            value: e.value,
                            barColor: e.value >= 85 ? AppTheme.accentCyan : AppTheme.lfcRed,
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Progress Tracker Card with Toggle Switches
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Evolution (Progress Tracker)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bật/tắt các chỉ số bên dưới để theo dõi sự phát triển qua từng mốc thời gian:',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allAttrKeys.map((attr) {
                        final isSelected = _selectedAttributes.contains(attr);
                        final attrIndex = allAttrKeys.indexOf(attr) % _chartColors.length;
                        final color = _chartColors[attrIndex];

                        return FilterChip(
                          selected: isSelected,
                          label: Text(
                            attr,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: AppTheme.surfaceNavyLight,
                          selectedColor: color.withValues(alpha: 0.3),
                          checkmarkColor: color,
                          side: BorderSide(
                            color: isSelected ? color : AppTheme.borderSubtle,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAttributes.add(attr);
                              } else {
                                if (_selectedAttributes.length > 1) {
                                  _selectedAttributes.remove(attr);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng chọn ít nhất 1 chỉ số để vẽ biểu đồ!')),
                                  );
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Biểu đồ đường cong LineChart
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (val) => const FlLine(
                              color: AppTheme.borderSubtle,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (val, meta) => Text(
                                  val.toInt().toString(),
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final int index = val.toInt();
                                  if (index >= 0 && index < currentPlayer.progressHistory.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        currentPlayer.progressHistory[index].date,
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          minY: 40,
                          maxY: 100,
                          lineBarsData: _selectedAttributes.map((attr) {
                            final attrIndex = allAttrKeys.indexOf(attr) % _chartColors.length;
                            final color = _chartColors[attrIndex];

                            final spots = <FlSpot>[];
                            for (int i = 0; i < currentPlayer.progressHistory.length; i++) {
                              final history = currentPlayer.progressHistory[i];
                              final val = history.attributes[attr] ?? 70.0;
                              spots.add(FlSpot(i.toDouble(), val));
                            }

                            return LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: color,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
