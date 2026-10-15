import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_avatar.dart';
import '../player/player_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _squadScrollController = ScrollController();

  @override
  void dispose() {
    _squadScrollController.dispose();
    super.dispose();
  }

  void _scrollSquad(double offsetDelta) {
    if (!_squadScrollController.hasClients) return;
    final target = (_squadScrollController.offset + offsetDelta).clamp(
      0.0,
      _squadScrollController.position.maxScrollExtent,
    );
    _squadScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  // Hộp thoại Sao lưu & Quản lý dữ liệu người dùng
  void _showDataManagementDialog(BuildContext context) {
    final state = context.read<AppStateProvider>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.storage, color: AppTheme.accentCyan, size: 22),
            SizedBox(width: 8),
            Text('Quản lý & Sao lưu Dữ liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tất cả chỉnh sửa ảnh cầu thủ, media PR đều được lưu vào bộ nhớ cục bộ thiết bị.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceNavyLight,
                child: Icon(Icons.copy, color: AppTheme.accentCyan, size: 20),
              ),
              title: const Text('Sao chép mã sao lưu (Backup JSON)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Lưu toàn bộ danh sách cầu thủ & ảnh đã đổi vào bộ nhớ tạm', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () {
                final jsonStr = jsonEncode(state.players.map((p) => p.toJson()).toList());
                Clipboard.setData(ClipboardData(text: jsonStr));
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép toàn bộ dữ liệu vào Clipboard!')),
                );
              },
            ),
            const Divider(color: AppTheme.borderSubtle),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceNavyLight,
                child: Icon(Icons.restore_page, color: AppTheme.lfcYellow, size: 20),
              ),
              title: const Text('Nhập mã khôi phục (Restore)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Dán mã sao lưu để nạp lại ảnh và chỉ số', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () {
                Navigator.of(dialogCtx).pop();
                _showRestoreDialog(context);
              },
            ),
            const Divider(color: AppTheme.borderSubtle),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceNavyLight,
                child: Icon(Icons.refresh, color: AppTheme.lfcRed, size: 20),
              ),
              title: const Text('Khôi phục mặc định ban đầu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.lfcRed)),
              subtitle: const Text('Xóa toàn bộ ảnh đã đổi và đưa về dữ liệu gốc', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              onTap: () async {
                await state.resetToDefaultMockData();
                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã khôi phục toàn bộ danh sách Liverpool về mặc định!')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (restoreCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Text('Dán mã dữ liệu sao lưu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Dán chuỗi JSON đã sao chép...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(restoreCtx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan, foregroundColor: Colors.black),
            onPressed: () async {
              try {
                final List<dynamic> list = jsonDecode(controller.text.trim());
                for (final item in list) {
                  final p = Player.fromJson(item as Map<String, dynamic>);
                  await context.read<AppStateProvider>().updatePlayer(p);
                }
                if (context.mounted) {
                  Navigator.of(restoreCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Khôi phục dữ liệu thành công!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mã dữ liệu không hợp lệ: $e')),
                  );
                }
              }
            },
            child: const Text('Nạp dữ liệu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeCount = state.players.where((p) => p.status == 'Active').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.lfcRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sports_soccer, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('Liverpool PMS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync_outlined),
            tooltip: 'Quản lý & Sao lưu dữ liệu',
            onPressed: () => _showDataManagementDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Club Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.surfaceNavyLight, Color(0xFF0F3460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AXA TRAINING CENTRE • SEASON 2026/2027',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppTheme.lfcYellow,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Liverpool Premier League Squad',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Under Manager Andoni Iraola. Portal for squad performance, training & Adidas commercial partners.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text('PARTNER', style: TextStyle(fontSize: 9, color: Colors.white70)),
                        Text('adidas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Key Metrics Row
            const Text(
              'Squad Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Total Squad',
                    value: state.players.length.toString(),
                    icon: Icons.groups,
                    accentColor: AppTheme.info,
                    onTap: () => widget.onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Active Fit',
                    value: activeCount.toString(),
                    icon: Icons.health_and_safety,
                    accentColor: AppTheme.success,
                    onTap: () => widget.onNavigateTab(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Sessions Today',
                    value: '${state.trainings.length}',
                    icon: Icons.timer,
                    accentColor: AppTheme.warning,
                    onTap: () => widget.onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Market Valuation',
                    value: '€${state.totalMarketValue.toStringAsFixed(0)}M',
                    icon: Icons.monetization_on,
                    accentColor: AppTheme.lfcYellow,
                    onTap: () => widget.onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Upcoming Training Sessions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Schedule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab(2),
                  child: const Text('View Calendar', style: TextStyle(color: AppTheme.lfcRed, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...state.trainings.take(2).map((session) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lfcRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center, color: AppTheme.lfcRed, size: 20),
                  ),
                  title: Text(session.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('${session.startTime} - ${session.endTime} • ${session.location}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(session.type, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Key Squad Profiles Header với Nút cuộn trái/phải & Chỉ báo số lượng
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Key Squad Profiles',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.lfcRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.lfcRed.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${state.players.length} cầu thủ',
                          style: const TextStyle(fontSize: 11, color: AppTheme.lfcRed, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Nút trượt trái
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  color: AppTheme.accentCyan,
                  tooltip: 'Cuộn sang trái',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _scrollSquad(-280),
                ),
                // Nút trượt phải
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  color: AppTheme.accentCyan,
                  tooltip: 'Cuộn sang phải',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _scrollSquad(280),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab(1),
                  child: const Text('All Players', style: TextStyle(color: AppTheme.lfcRed, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Horizontal Scrollable Key Squad Profiles với thanh cuộn Scrollbar và hỗ trợ kéo chuột / vuốt chạm
            SizedBox(
              height: 180,
              child: Scrollbar(
                controller: _squadScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: ListView.separated(
                  controller: _squadScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.players.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final p = state.players[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerDetailScreen(player: p),
                          ),
                        );
                      },
                      child: Container(
                        width: 136,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PlayerAvatar(
                              imageUrl: p.avatarUrl,
                              radius: 26,
                              initials: p.name.isNotEmpty ? p.name[0] : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${p.number} • ${p.position.name.toUpperCase()}',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '€${p.currentMarketValue.toStringAsFixed(0)}M',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.lfcYellow),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                Icon(icon, size: 18, color: accentColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
