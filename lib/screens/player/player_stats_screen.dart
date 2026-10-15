import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
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
  // Selected attributes for Progress chart toggles
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
    // Default select first two attributes
    final keys = widget.player.latestAttributes.keys.toList();
    _selectedAttributes = keys.take(2).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final attributes = widget.player.latestAttributes;
    final allAttrKeys = attributes.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.player.name} - Stats & Progress'),
        actions: [
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
                  widget.player.positionName,
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
            // Dynamic Position Notice Banner
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
                      'Position-Adaptive Metrics: Bộ chỉ số đánh giá được tự động tối ưu hóa riêng cho vị trí ${widget.player.position.name.toUpperCase()}.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
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
                          'Position Radar Evaluation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCardLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Latest Session', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: RadarChartWidget(
                        attributes: attributes,
                        lineColor: AppTheme.lfcRed,
                        fillColor: AppTheme.lfcRed.withValues(alpha: 0.35),
                      ),
                    ),
                    const Divider(color: AppTheme.borderSubtle, height: 32),
                    const Text(
                      'Attribute Breakdown',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    ...attributes.entries.map((entry) {
                      return StatProgressBar(
                        label: entry.key,
                        value: entry.value,
                        barColor: entry.value >= 90
                            ? AppTheme.lfcYellow
                            : (entry.value >= 80 ? AppTheme.lfcRed : AppTheme.textSecondary),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Progress Tracker (Bật/tắt chỉ số theo dõi qua thời gian)
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
                          'Performance Progress Timeline',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const Icon(Icons.trending_up, color: AppTheme.success, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bật / tắt các chỉ số bên dưới để so sánh biểu đồ tiến bộ qua các tháng:',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips (Toggle Buttons)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allAttrKeys.map((attr) {
                        final isSelected = _selectedAttributes.contains(attr);
                        final attrIndex = allAttrKeys.indexOf(attr) % _chartColors.length;
                        final color = _chartColors[attrIndex];

                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(attr),
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: color.withValues(alpha: 0.25),
                          checkmarkColor: color,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAttributes.add(attr);
                              } else {
                                if (_selectedAttributes.length > 1) {
                                  _selectedAttributes.remove(attr);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng chọn ít nhất 1 chỉ số để vẽ biểu đồ.')),
                                  );
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Line Chart
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) => const FlLine(
                              color: AppTheme.borderSubtle,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
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
                                  if (index >= 0 && index < widget.player.progressHistory.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        widget.player.progressHistory[index].date,
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
                          minY: 65,
                          maxY: 100,
                          lineBarsData: _selectedAttributes.map((attr) {
                            final attrIndex = allAttrKeys.indexOf(attr) % _chartColors.length;
                            final color = _chartColors[attrIndex];

                            final spots = <FlSpot>[];
                            for (int i = 0; i < widget.player.progressHistory.length; i++) {
                              final history = widget.player.progressHistory[i];
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
