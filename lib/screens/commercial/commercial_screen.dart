import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class CommercialScreen extends StatelessWidget {
  const CommercialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final totalValue = state.totalMarketValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commercial & Sponsorship'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Squad Market Value Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Squad Total Market Value',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 12, color: AppTheme.success),
                              SizedBox(width: 2),
                              Text('+5.8% (Q1 2026)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '€${totalValue.toStringAsFixed(1)}M',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.lfcYellow,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Estimated squad valuation benchmarked against European transfer index',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const Divider(color: AppTheme.borderSubtle, height: 28),

                    // Top Valuable Players Chart Preview
                    const Text(
                      'Top Player Valuations',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 140,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final int index = val.toInt();
                                  if (index >= 0 && index < state.players.length) {
                                    final p = state.players[index];
                                    final shortName = p.name.split(' ').last;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        shortName,
                                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: state.players.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final p = entry.value;
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: p.currentMarketValue,
                                  color: AppTheme.lfcRed,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
            const SizedBox(height: 20),

            // Sponsor Feature: Adidas Official Partnership
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.lfcYellow, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.adidasBlack,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.workspace_premium, color: AppTheme.lfcYellow, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'adidas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Official Kit & Sportswear Partner',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.success.withValues(alpha: 0.5)),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.borderSubtle, height: 28),
                    _buildPartnershipRow('Contract Period', '2025 - 2030 (Multi-Year Deal)'),
                    const SizedBox(height: 8),
                    _buildPartnershipRow('Contract Annual Value', '£60,000,000+ / Season'),
                    const SizedBox(height: 8),
                    _buildPartnershipRow('Key Sponsored Athletes', 'Mohamed Salah, Trent Alexander-Arnold'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Active Campaigns Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Adidas PR & Marketing Campaigns',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  '${state.campaigns.length} campaigns',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.campaigns.length,
              itemBuilder: (context, index) {
                final c = state.campaigns[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.lfcRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.status,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.lfcRed),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(c.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildCampaignMetric('Reach', c.reach, Icons.remove_red_eye_outlined),
                            const SizedBox(width: 20),
                            _buildCampaignMetric('Engagement', c.engagement, Icons.thumb_up_alt_outlined),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: c.featuredPlayerNames.map((pName) {
                            return Chip(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              label: Text(pName, style: const TextStyle(fontSize: 10)),
                              backgroundColor: AppTheme.bgCardLight,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnershipRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildCampaignMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.lfcYellow),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ],
    );
  }
}
