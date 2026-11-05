import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import 'campaign_management_screen.dart';
import 'sponsorship_management_screen.dart';

class CommercialScreen extends StatelessWidget {
  const CommercialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final topPlayers = [...state.players]
      ..sort((a, b) => b.currentMarketValue.compareTo(a.currentMarketValue));
    final chartPlayers = topPlayers.take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commercial & Sponsorship'),
        actions: [
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: state.isDarkMode
                  ? AppTheme.accentGold
                  : Colors.amber.shade700,
            ),
            tooltip: state.isDarkMode
                ? 'Chuyển sang Giao diện Sáng'
                : 'Chuyển sang Giao diện Tối',
            onPressed: () => context.read<AppStateProvider>().toggleTheme(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Quản lý hoạt động thương mại',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn một mục để quản lý đối tác tài trợ hoặc chiến dịch.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          _NavigationCard(
            icon: Icons.handshake_outlined,
            title: 'Sponsorship management',
            subtitle:
                '${state.sponsorships.length} nhà tài trợ • Danh sách logo & hợp đồng',
            color: AppTheme.accentCyan,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SponsorshipManagementScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _NavigationCard(
            icon: Icons.campaign_outlined,
            title: 'Campaign management',
            subtitle: '${state.campaigns.length} chiến dịch ',
            color: AppTheme.lfcYellow,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CampaignManagementScreen(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giá trị thị trường đội hình',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '€${state.totalMarketValue.toStringAsFixed(1)}M',
                    style: const TextStyle(
                      color: AppTheme.lfcYellow,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Định giá Transfermarkt & bản quyền hình ảnh đội 1 Liverpool FC',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const Divider(color: AppTheme.borderSubtle, height: 28),
                  const Text(
                    'Top 8 cầu thủ có giá trị cao nhất',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (chartPlayers.isEmpty)
                    const SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'Chưa có dữ liệu cầu thủ.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 170,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: chartPlayers.first.currentMarketValue * 1.25,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= chartPlayers.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      chartPlayers[index].name.split(' ').last,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 9,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: chartPlayers.asMap().entries.map((entry) {
                            final index = entry.key;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.currentMarketValue,
                                  color: index == 0
                                      ? AppTheme.lfcYellow
                                      : (index < 3
                                            ? AppTheme.accentCyan
                                            : AppTheme.lfcRed),
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
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
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
