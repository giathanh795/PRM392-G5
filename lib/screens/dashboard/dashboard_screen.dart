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

  // Hộp thoại thêm tân binh / Ký hợp đồng cầu thủ mới
  void _showAddPlayerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final numberController = TextEditingController(text: '10');
    final valController = TextEditingController(text: '45.0');
    final natController = TextEditingController(text: 'England');
    final dobController = TextEditingController(text: '2004-05-15');
    final contractController = TextEditingController(text: '2030-06-30');
    PlayerPosition selectedPos = PlayerPosition.forward;

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
              Icon(Icons.person_add_alt_1, color: AppTheme.accentCyan, size: 22),
              SizedBox(width: 8),
              Text('Ký Hợp Đồng Tân Binh Mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên cầu thủ tân binh', hintText: 'Ví dụ: Jude Bellingham'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Số áo (#)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: valController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Định giá (€M)', prefixText: '€'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Vị trí sở trường:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: PlayerPosition.values.map((pos) {
                    final isSel = selectedPos == pos;
                    return ChoiceChip(
                      label: Text(pos.name.toUpperCase()),
                      selected: isSel,
                      selectedColor: AppTheme.accentBlue,
                      onSelected: (_) => setDialogState(() => selectedPos = pos),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: natController,
                  decoration: const InputDecoration(labelText: 'Quốc tịch'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contractController,
                  decoration: const InputDecoration(labelText: 'Hạn hợp đồng (YYYY-MM-DD)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentCyan, foregroundColor: Colors.black),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final num = int.tryParse(numberController.text.trim()) ?? 99;
                final val = double.tryParse(valController.text.trim()) ?? 30.0;

                final newPlayer = Player(
                  id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  number: num,
                  position: selectedPos,
                  nationality: natController.text.trim(),
                  dateOfBirth: dobController.text.trim(),
                  preferredFoot: 'Right',
                  height: '185 cm',
                  weight: '78 kg',
                  contractUntil: contractController.text.trim(),
                  avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80',
                  currentMarketValue: val,
                  previousMarketValue: val,
                  status: 'Active',
                  sponsorPartner: 'Adidas',
                  progressHistory: [
                    PlayerStatistic(date: 'Oct', attributes: {'Pace': 85.0, 'Shooting': 82.0, 'Passing': 84.0, 'Dribbling': 86.0, 'Defending': 65.0, 'Physical': 80.0}),
                  ],
                  marketValueHistory: [
                    MarketValuePoint(date: 'Oct', valueInMillionsEuro: val),
                  ],
                  mediaList: [],
                );

                await context.read<AppStateProvider>().addPlayer(newPlayer);
                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã hoàn tất ký hợp đồng với tân binh $name!')),
                  );
                }
              },
              child: const Text('Ký hợp đồng'),
            ),
          ],
        ),
      ),
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
    final injuredCount = state.players.where((p) => p.status == 'Injured').length;
    final doubtfulCount = state.players.where((p) => p.status == 'Doubtful' || p.status == 'On Duty').length;

    // Phân bổ cầu thủ theo 4 tuyến
    final fwCount = state.players.where((p) => p.position == PlayerPosition.forward).length;
    final mfCount = state.players.where((p) => p.position == PlayerPosition.midfielder).length;
    final dfCount = state.players.where((p) => p.position == PlayerPosition.defender).length;
    final gkCount = state.players.where((p) => p.position == PlayerPosition.goalkeeper).length;

    final fwVal = state.players.where((p) => p.position == PlayerPosition.forward).fold(0.0, (s, p) => s + p.currentMarketValue);
    final mfVal = state.players.where((p) => p.position == PlayerPosition.midfielder).fold(0.0, (s, p) => s + p.currentMarketValue);
    final dfVal = state.players.where((p) => p.position == PlayerPosition.defender).fold(0.0, (s, p) => s + p.currentMarketValue);
    final gkVal = state.players.where((p) => p.position == PlayerPosition.goalkeeper).fold(0.0, (s, p) => s + p.currentMarketValue);

    // Cầu thủ có giá trị cao nhất & Cầu thủ đang chấn thương
    final topPlayer = (List<Player>.from(state.players)..sort((a, b) => b.currentMarketValue.compareTo(a.currentMarketValue))).firstOrNull;
    final injuredPlayers = state.players.where((p) => p.status == 'Injured').toList();

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
          // Nút Đồng bộ Live Data (Real-time Sync)
          IconButton(
            icon: state.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentCyan),
                  )
                : const Icon(Icons.sync, color: AppTheme.accentCyan),
            tooltip: 'Đồng bộ dữ liệu thời gian thực',
            onPressed: state.isSyncing
                ? null
                : () async {
                    await state.syncRealtimeData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã đồng bộ giá trị thị trường & thể lực Premier League mới nhất!')),
                      );
                    }
                  },
          ),
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
            // Welcome Club Banner với trạng thái Backend & Realtime
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
              child: Column(
                children: [
                  Row(
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
                              'Liverpool Squad Command Hub',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Bản điều khiển quản lý nhân sự, lộ trình thể lực và bản quyền thương mại Adidas dưới HLV Andoni Iraola.',
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
                  const SizedBox(height: 12),
                  // Real-time Status Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: state.isBackendConnected ? Colors.greenAccent : AppTheme.warning,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.isBackendConnected ? 'Backend Server Online (Port 8080)' : 'Chế độ Local Storage',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                        Text(
                          state.lastSyncTime != null
                              ? 'Cập nhật: ${state.lastSyncTime!.hour}:${state.lastSyncTime!.minute.toString().padLeft(2, '0')}'
                              : 'Chưa đồng bộ live',
                          style: const TextStyle(fontSize: 10, color: AppTheme.accentCyan),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- THANH TÁC VỤ QUẢN LÝ NHANH CHO ÔNG BẦU / HLV (3 QUICK ACTION BUTTONS) ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Ký Tân Binh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddPlayerDialog(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceNavyLight,
                      foregroundColor: AppTheme.accentCyan,
                      side: const BorderSide(color: AppTheme.accentCyan),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.fitness_center, size: 16),
                    label: const Text('Lên Lịch AXA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => widget.onNavigateTab(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceNavyLight,
                      foregroundColor: AppTheme.lfcYellow,
                      side: const BorderSide(color: AppTheme.lfcYellow),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.campaign, size: 16),
                    label: const Text('Tài Trợ Adidas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => widget.onNavigateTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- KHỐI 1: SQUAD READINESS MATRIX (TRẠNG THÁI THỂ LỰC & Y TẾ TOÀN ĐỘI) ---
            const Text(
              'Squad Readiness & Medical Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildReadinessCard(
                    title: 'Match Fit',
                    count: activeCount,
                    total: state.players.length,
                    color: AppTheme.success,
                    icon: Icons.check_circle_outline,
                    subtitle: 'Sẵn sàng thi đấu 100%',
                    onTap: () => widget.onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildReadinessCard(
                    title: 'Doubtful / Fatigue',
                    count: doubtfulCount,
                    total: state.players.length,
                    color: AppTheme.warning,
                    icon: Icons.access_time,
                    subtitle: 'Cần giảm tải giáo án',
                    onTap: () => widget.onNavigateTab(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildReadinessCard(
                    title: 'Injured',
                    count: injuredCount,
                    total: state.players.length,
                    color: AppTheme.danger,
                    icon: Icons.healing,
                    subtitle: 'Đang phục hồi tại AXA',
                    onTap: () => widget.onNavigateTab(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cảnh báo y tế chi tiết nếu có ca chấn thương
            if (injuredPlayers.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Phòng y tế AXA: ${injuredPlayers.map((p) => '#${p.number} ${p.name}').join(', ')} đang được điều trị chuyên sâu, không tham gia các bài tập đối kháng.',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // --- KHỐI 2: SPOTLIGHT CẦU THỦ ĐẮT GIÁ NHẤT & ĐỘI TRƯỞNG ---
            if (topPlayer != null) ...[
              const Text(
                'Squad Valuation Leader (Transfermarkt Top Asset)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: topPlayer)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.lfcYellow.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      PlayerAvatar(
                        imageUrl: topPlayer.avatarUrl,
                        radius: 32,
                        initials: topPlayer.name[0],
                        borderColor: AppTheme.lfcYellow,
                        borderWidth: 2,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lfcYellow.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('TOP ASSET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.lfcYellow)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  topPlayer.nationality,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${topPlayer.number} ${topPlayer.name}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${topPlayer.positionName} • Hợp đồng đến ${topPlayer.contractUntil}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Định giá', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                          Text(
                            '€${topPlayer.currentMarketValue.toStringAsFixed(0)}M',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.lfcYellow),
                          ),
                          const Text('Transfermarkt', style: TextStyle(fontSize: 9, color: AppTheme.accentCyan)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // --- KHỐI 3: BIỂU ĐỒ CHIỀU SÂU ĐỘI HÌNH & PHÂN BỔ TUYẾN (POSITION MATRIX) ---
            const Text(
              'Squad Depth & Valuation by Position',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cơ cấu chiều sâu 25 cầu thủ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        Text('Tổng: €${state.totalMarketValue.toStringAsFixed(0)}M', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.lfcYellow)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // 4 thanh đo chiều sâu theo tuyến
                    _buildPositionDepthBar('Tiền đạo (Forwards)', fwCount, 25, fwVal, AppTheme.lfcRed),
                    const SizedBox(height: 10),
                    _buildPositionDepthBar('Tiền vệ (Midfielders)', mfCount, 25, mfVal, AppTheme.accentBlue),
                    const SizedBox(height: 10),
                    _buildPositionDepthBar('Hậu vệ (Defenders)', dfCount, 25, dfVal, AppTheme.accentCyan),
                    const SizedBox(height: 10),
                    _buildPositionDepthBar('Thủ môn (Goalkeepers)', gkCount, 25, gkVal, AppTheme.lfcYellow),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- KHỐI 4: KEY SQUAD PROFILES HÀNG NGANG CUỘN MƯỢT ---
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  color: AppTheme.accentCyan,
                  tooltip: 'Cuộn sang trái',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _scrollSquad(-280),
                ),
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

            // Horizontal Scrollable Key Squad Profiles
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
            const SizedBox(height: 20),

            // --- KHỐI 5: LỊCH TẬP HUẤN HÔM NAY CỦA CÁC CẦU THỦ ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Training Sessions at AXA',
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
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessCard({
    required String title,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: color),
                Text('$count/$total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionDepthBar(String label, int count, int total, double val, Color color) {
    final pct = (count / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text('$count cầu thủ • €${val.toStringAsFixed(0)}M', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.surfaceNavyLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
