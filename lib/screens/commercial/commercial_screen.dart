import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../../models/sponsor_campaign.dart';
import 'package:fl_chart/fl_chart.dart';

class CommercialScreen extends StatelessWidget {
  const CommercialScreen({super.key});

  // Hộp thoại tạo chiến dịch quảng bá / ký hợp đồng tài trợ Adidas mới
  void _showAddCampaignDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final budgetController = TextEditingController(text: '1.5');
    final reachController = TextEditingController(text: '3.5M');
    final engageController = TextEditingController(text: '9.2%');
    final startController = TextEditingController(text: '2026-11-01');
    final endController = TextEditingController(text: '2027-01-31');

    String selectedCategory = 'Footwear';
    final selectedPlayers = <String>{'Florian Wirtz', 'Alexander Isak'};
    final allPlayers = context.read<AppStateProvider>().players;

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
              Icon(Icons.campaign, color: AppTheme.lfcYellow, size: 22),
              SizedBox(width: 8),
              Text('Tạo Chiến Dịch Adidas Mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên chiến dịch PR / Thương mại',
                      hintText: 'Ví dụ: Adidas Predator 2027 Global Launch',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: budgetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Ngân sách (€M)', prefixText: '€'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: reachController,
                          decoration: const InputDecoration(labelText: 'Dự kiến tiếp cận (Reach)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Dòng sản phẩm tài trợ:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: ['Footwear', 'Apparel', 'Digital Content', 'Community'].map((cat) {
                      final isSel = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: AppTheme.accentBlue,
                        onSelected: (_) => setDialogState(() => selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startController,
                          decoration: const InputDecoration(labelText: 'Ngày bắt đầu (YYYY-MM-DD)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: endController,
                          decoration: const InputDecoration(labelText: 'Ngày kết thúc (YYYY-MM-DD)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Nội dung & Mục tiêu thương mại'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Cầu thủ đại sứ chiến dịch:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allPlayers.take(12).map((p) {
                      final isSel = selectedPlayers.contains(p.name);
                      return FilterChip(
                        selected: isSel,
                        label: Text(p.name, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppTheme.surfaceNavyLight,
                        selectedColor: AppTheme.accentBlue,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedPlayers.add(p.name);
                            } else {
                              selectedPlayers.remove(p.name);
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
                backgroundColor: AppTheme.lfcYellow,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên chiến dịch!')),
                  );
                  return;
                }

                final newCamp = SponsorCampaign(
                  id: 'camp_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  sponsorName: 'Adidas',
                  startDate: startController.text.trim(),
                  endDate: endController.text.trim(),
                  status: 'Active',
                  reach: reachController.text.trim(),
                  engagement: engageController.text.trim(),
                  description: descController.text.trim(),
                  category: selectedCategory,
                  budgetMillions: double.tryParse(budgetController.text.trim()) ?? 1.5,
                  featuredPlayerNames: selectedPlayers.toList(),
                );

                await context.read<AppStateProvider>().addCampaign(newCamp);
                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã ký kết và phát động chiến dịch: $name!')),
                  );
                }
              },
              child: const Text('Ký kết & Phát động'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final totalValue = state.totalMarketValue;

    // Top 8 cầu thủ giá trị cao nhất
    final sortedPlayers = List.from(state.players)
      ..sort((a, b) => b.currentMarketValue.compareTo(a.currentMarketValue));
    final topPlayers = sortedPlayers.take(8).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commercial & Sponsorship'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business, color: AppTheme.lfcYellow),
            tooltip: 'Tạo chiến dịch tài trợ Adidas',
            onPressed: () => _showAddCampaignDialog(context),
          ),
        ],
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
                              Text('+5.8% (2026/2027 Index)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success)),
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
                      'Định giá Transfermarkt & Bản quyền hình ảnh đội 1 Liverpool FC',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const Divider(color: AppTheme.borderSubtle, height: 28),

                    // Top Valuable Players Chart Preview
                    const Text(
                      'Top 8 Cầu Thủ Giá Trị Chuyển Nhượng Cao Nhất',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 160,
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
                                  if (index >= 0 && index < topPlayers.length) {
                                    final p = topPlayers[index];
                                    final shortName = p.name.split(' ').last;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Text(
                                        shortName,
                                        style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
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
                          barGroups: topPlayers.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final p = entry.value;
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: p.currentMarketValue,
                                  color: idx == 0 ? AppTheme.lfcYellow : (idx < 3 ? AppTheme.accentCyan : AppTheme.lfcRed),
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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

            // Adidas Official Partnership Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.adidasBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: AppTheme.accentCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ADIDAS OFFICIAL SPONSORSHIP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Active Partner', style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Exclusive Global Sportswear & Kit Supplier Contract',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hợp đồng tài trợ trang phục thi đấu chính thức, giày đinh chuyên dụng và trang thiết bị tập huấn trung tâm AXA.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  _buildPartnershipRow('Contract Period', '2026 - 2031 (5-Year Term)'),
                  const SizedBox(height: 6),
                  _buildPartnershipRow('Annual Partnership Value', '£75,000,000 / Season'),
                  const SizedBox(height: 6),
                  _buildPartnershipRow('Key Athletes Endorsed', 'Florian Wirtz, Alexander Isak, Szoboszlai'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Campaigns Section với Nút "+ Tạo Chiến Dịch"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Adidas PR & Marketing Campaigns',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceNavyLight,
                    foregroundColor: AppTheme.lfcYellow,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm chiến dịch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddCampaignDialog(context),
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
                            const SizedBox(width: 16),
                            _buildCampaignMetric('Engagement', c.engagement, Icons.thumb_up_alt_outlined),
                            const SizedBox(width: 16),
                            _buildCampaignMetric('Budget', '€${c.budgetMillions}M', Icons.attach_money),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Wrap(
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
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                              tooltip: 'Xóa chiến dịch',
                              onPressed: () {
                                context.read<AppStateProvider>().deleteCampaign(c.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã xóa chiến dịch')),
                                );
                              },
                            ),
                          ],
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
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
