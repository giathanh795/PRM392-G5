import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_avatar.dart';
import '../player/player_detail_screen.dart';
import 'dashboard_overview.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _squadScrollController = ScrollController();
  int _viewMode =
      1;

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

  void _showAddPlayerDialog(BuildContext parentContext) {
    final nameController = TextEditingController();
    final numberController = TextEditingController(text: '10');
    final valController = TextEditingController(text: '45.0');
    final natController = TextEditingController(text: 'England');
    final dobController = TextEditingController(text: '2004-05-15');
    final contractController = TextEditingController(text: '2030-06-30');
    PlayerPosition selectedPos = PlayerPosition.forward;

    showDialog(
      context: parentContext,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogStateCtx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.person_add_alt_1,
                color: AppTheme.accentCyan,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Ký Hợp Đồng Tân Binh Mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên players tân binh',
                    hintText: 'Ví dụ: Jude Bellingham',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số áo (#)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: valController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Định giá (€M)',
                          prefixText: '€',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vị trí sở trường:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: PlayerPosition.values.map((pos) {
                    final isSel = selectedPos == pos;
                    return ChoiceChip(
                      label: Text(pos.name.toUpperCase()),
                      selected: isSel,
                      selectedColor: AppTheme.accentBlue,
                      onSelected: (_) =>
                          setDialogState(() => selectedPos = pos),
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
                  decoration: const InputDecoration(
                    labelText: 'Hạn hợp đồng (YYYY-MM-DD)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.black,
              ),
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
                    PlayerStatistic(
                      date: 'Oct',
                      attributes: {
                        'Pace': 85.0,
                        'Shooting': 82.0,
                        'Passing': 84.0,
                        'Dribbling': 86.0,
                        'Defending': 65.0,
                        'Physical': 80.0,
                      },
                    ),
                  ],
                  marketValueHistory: [
                    MarketValuePoint(date: 'Oct', valueInMillionsEuro: val),
                  ],
                  mediaList: [],
                );

                Navigator.of(dialogCtx).pop();
                await parentContext.read<AppStateProvider>().addPlayer(newPlayer);
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã hoàn tất ký hợp đồng với tân binh $name!',
                      ),
                    ),
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
            Text(
              'Quản lý & Sao lưu Dữ liệu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tất cả chỉnh sửa ảnh players, media PR đều được lưu vào bộ nhớ cục bộ thiết bị.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceNavyLight,
                child: Icon(Icons.copy, color: AppTheme.accentCyan, size: 20),
              ),
              title: const Text(
                'Sao chép mã sao lưu (Backup JSON)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Lưu toàn bộ danh sách players & ảnh đã đổi vào bộ nhớ tạm',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: () {
                final jsonStr = jsonEncode(
                  state.players.map((p) => p.toJson()).toList(),
                );
                Clipboard.setData(ClipboardData(text: jsonStr));
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép toàn bộ dữ liệu vào Clipboard!'),
                  ),
                );
              },
            ),
            const Divider(color: AppTheme.borderSubtle),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.surfaceNavyLight,
                child: Icon(
                  Icons.restore_page,
                  color: AppTheme.lfcYellow,
                  size: 20,
                ),
              ),
              title: const Text(
                'Nhập mã khôi phục (Restore)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Dán mã sao lưu để nạp lại ảnh và chỉ số',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
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
              title: const Text(
                'Khôi phục mặc định ban đầu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lfcRed,
                ),
              ),
              subtitle: const Text(
                'Xóa toàn bộ ảnh đã đổi và đưa về dữ liệu gốc',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: () async {
                Navigator.of(dialogCtx).pop();
                await state.resetToDefaultMockData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã khôi phục toàn bộ danh sách Liverpool về mặc định!',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(
              'Đóng',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
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
        title: const Text(
          'Dán mã dữ liệu sao lưu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.black,
            ),
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
                    const SnackBar(
                      content: Text('Khôi phục dữ liệu thành công!'),
                    ),
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

  void _showActivityNotificationCenter(BuildContext context) {
    final state = context.read<AppStateProvider>();
    final injured = state.players.where((p) => p.isInjured || p.isDoubtful).toList();
    final expiring = state.players.where((p) => p.isContractExpiringSoon).toList();
    final campaigns = state.campaigns;
    final trainings = state.trainings;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceNavy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.lfcRed.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active, color: AppTheme.lfcRed, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Nhật ký Hoạt động & Thông báo CLB',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderSubtle),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildNotificationTile(
                    icon: Icons.medical_services_outlined,
                    iconColor: AppTheme.danger,
                    title: 'Báo cáo Y tế AXA: ${injured.length} cầu thủ cần lưu ý',
                    subtitle: injured.isNotEmpty
                        ? injured.map((p) => '${p.name} (${p.status})').join(', ')
                        : 'Toàn bộ đội hình đều đạt 100% thể lực thi đấu.',
                    time: 'Hôm nay',
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(1);
                    },
                  ),
                  _buildNotificationTile(
                    icon: Icons.timer_outlined,
                    iconColor: AppTheme.lfcYellow,
                    title: 'Cảnh báo Hợp đồng: ${expiring.length} cầu thủ sắp đáo hạn',
                    subtitle: expiring.isNotEmpty
                        ? 'Cần lên kế hoạch gia hạn cho: ${expiring.map((p) => p.name).take(3).join(", ")}'
                        : 'Không có cầu thủ nào sắp hết hạn hợp đồng.',
                    time: 'Ưu tiên',
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(1);
                    },
                  ),
                  _buildNotificationTile(
                    icon: Icons.campaign_outlined,
                    iconColor: AppTheme.accentCyan,
                    title: 'Chiến dịch Đối tác: ${campaigns.length} chiến dịch đang hoạt động',
                    subtitle: campaigns.isNotEmpty
                        ? campaigns.first.name
                        : 'Đang đàm phán hợp đồng thương mại mới.',
                    time: 'Đang diễn ra',
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(3);
                    },
                  ),
                  _buildNotificationTile(
                    icon: Icons.fitness_center_outlined,
                    iconColor: AppTheme.success,
                    title: 'Lịch tập Huấn luyện: ${trainings.length} buổi tập tại AXA Ground',
                    subtitle: trainings.isNotEmpty
                        ? trainings.first.title
                        : 'Chưa có buổi tập nào được lên lịch.',
                    time: 'Tuần này',
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onNavigateTab(2);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.surfaceNavyLight,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(time, style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.bold)),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeCount = state.players.where((p) => p.status == 'Active').length;
    final injuredCount = state.players
        .where((p) => p.status == 'Injured')
        .length;
    final doubtfulCount = state.players
        .where((p) => p.status == 'Doubtful' || p.status == 'On Duty')
        .length;

    final fwCount = state.players
        .where((p) => p.position == PlayerPosition.forward)
        .length;
    final mfCount = state.players
        .where((p) => p.position == PlayerPosition.midfielder)
        .length;
    final dfCount = state.players
        .where((p) => p.position == PlayerPosition.defender)
        .length;
    final gkCount = state.players
        .where((p) => p.position == PlayerPosition.goalkeeper)
        .length;

    final fwVal = state.players
        .where((p) => p.position == PlayerPosition.forward)
        .fold(0.0, (s, p) => s + p.currentMarketValue);
    final mfVal = state.players
        .where((p) => p.position == PlayerPosition.midfielder)
        .fold(0.0, (s, p) => s + p.currentMarketValue);
    final dfVal = state.players
        .where((p) => p.position == PlayerPosition.defender)
        .fold(0.0, (s, p) => s + p.currentMarketValue);
    final gkVal = state.players
        .where((p) => p.position == PlayerPosition.goalkeeper)
        .fold(0.0, (s, p) => s + p.currentMarketValue);

    final topPlayer =
        (List<Player>.from(state.players)..sort(
              (a, b) => b.currentMarketValue.compareTo(a.currentMarketValue),
            ))
            .firstOrNull;
    final injuredPlayers = state.players
        .where((p) => p.isInjured)
        .toList();
    final expiringSoonPlayers = state.players
        .where((p) => p.isContractExpiringSoon)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 84,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
          child: InkWell(
            key: const ValueKey('language-toggle-btn'),
            borderRadius: BorderRadius.circular(20),
            onTap: () => state.toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceNavyLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.accentCyan.withValues(alpha: 0.6),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.isVietnamese ? '🇻🇳 VI' : '🇬🇧 EN',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/liverpool.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sports_soccer,
                    size: 16,
                    color: AppTheme.lfcRed,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                state.isVietnamese
                    ? 'Liverpool FC - Quản lý Cầu thủ'
                    : 'Liverpool FC - Player Management',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [

          IconButton(
            icon: state.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentCyan,
                    ),
                  )
                : const Icon(Icons.sync, color: AppTheme.accentCyan),
            tooltip: 'Đồng bộ dữ liệu thời gian thực',
            onPressed: state.isSyncing
                ? null
                : () async {
                    await state.syncRealtimeData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đã đồng bộ giá trị thị trường & thể lực Premier League mới nhất!',
                          ),
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Colors.white),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppTheme.lfcRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '${(state.players.where((p) => p.isInjured || p.isDoubtful).length + state.players.where((p) => p.isContractExpiringSoon).length).clamp(1, 9)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Nhật ký & Thông báo CLB',
            onPressed: () => _showActivityNotificationCenter(context),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync_outlined),
            tooltip: 'Quản lý & Sao lưu dữ liệu',
            onPressed: () => _showDataManagementDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [

          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.isDark(context)
                    ? [
                        AppTheme.surfaceNavyLight,
                        AppTheme.surfaceNavy,
                      ]
                    : [
                        Colors.white,
                        const Color(0xFFF8FAFC),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.lfcYellow.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.lfcYellow, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.lfcYellow.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      state.userProfile.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        color: AppTheme.lfcYellow,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              state.userProfile.fullName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textColor(context),
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.lfcYellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OWNER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.lfcYellow,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.isVietnamese
                            ? 'Tổng giá trị đội hình: €${state.totalMarketValue.toStringAsFixed(1)}M • ${state.players.length} Cầu thủ đội 1'
                            : 'Squad Value: €${state.totalMarketValue.toStringAsFixed(1)}M • ${state.players.length} Players',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.subtextColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => widget.onNavigateTab(4),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.lfcRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.lfcRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.manage_accounts_outlined, size: 14, color: AppTheme.lfcRed),
                        const SizedBox(width: 4),
                        Text(
                          state.isVietnamese ? 'Hồ sơ' : 'Profile',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.lfcRed),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceNavyLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() => _viewMode = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _viewMode == 0
                            ? AppTheme.lfcRed
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dashboard_customize_rounded,
                            size: 16,
                            color: _viewMode == 0
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              state.isVietnamese
                                  ? 'Trung tâm chỉ huy'
                                  : 'Command centre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _viewMode == 0
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() => _viewMode = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _viewMode == 1
                            ? AppTheme.accentBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 16,
                            color: _viewMode == 1
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              state.isVietnamese
                                  ? 'Tổng quan CLB'
                                  : 'Club overview',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _viewMode == 1
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _viewMode == 1
                ? DashboardOverview(
                    state: state,
                    onNavigateTab: widget.onNavigateTab,
                    onManageData: () => _showDataManagementDialog(context),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.surfaceNavyLight,
                                Color(0xFF0F3460),
                              ],
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Column(
                                      children: [
                                        Text(
                                          'PARTNER',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          'adidas',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: state.isBackendConnected
                                              ? Colors.greenAccent
                                              : AppTheme.warning,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          state.isBackendConnected
                                              ? 'Backend online'
                                              : 'Offline mode',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      state.lastSyncTime != null
                                          ? 'Updated: ${state.lastSyncTime!.hour}:${state.lastSyncTime!.minute.toString().padLeft(2, '0')}'
                                          : 'Not synced',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.accentCyan,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.person_add, size: 16),
                                label: Text(
                                  state.tr('sign_player'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => _showAddPlayerDialog(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceNavyLight,
                                  foregroundColor: AppTheme.accentCyan,
                                  side: const BorderSide(
                                    color: AppTheme.accentCyan,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                ),
                                label: Text(
                                  state.tr('schedule_axa'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => widget.onNavigateTab(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.surfaceNavyLight,
                                  foregroundColor: AppTheme.lfcYellow,
                                  side: const BorderSide(
                                    color: AppTheme.lfcYellow,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.campaign, size: 16),
                                label: Text(
                                  state.tr('sponsorship_action'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () => widget.onNavigateTab(3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Text(
                          state.tr('squad_readiness'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildReadinessCard(
                                title: state.tr('match_fit'),
                                count: activeCount,
                                total: state.players.length,
                                color: AppTheme.success,
                                icon: Icons.check_circle_outline,
                                subtitle: state.tr('match_fit_sub'),
                                onTap: () => widget.onNavigateTab(1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildReadinessCard(
                                title: state.tr('doubtful'),
                                count: doubtfulCount,
                                total: state.players.length,
                                color: AppTheme.warning,
                                icon: Icons.access_time,
                                subtitle: state.tr('doubtful_sub'),
                                onTap: () => widget.onNavigateTab(1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildReadinessCard(
                                title: state.tr('injured'),
                                count: injuredCount,
                                total: state.players.length,
                                color: AppTheme.danger,
                                icon: Icons.healing,
                                subtitle: state.tr('injured_sub'),
                                onTap: () => widget.onNavigateTab(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (injuredPlayers.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppTheme.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    state.isVietnamese
                                        ? 'Phòng y tế AXA: ${injuredPlayers.map((p) => '#${p.number} ${p.name}').join(', ')} đang được điều trị chuyên sâu, không tham gia các bài tập đối kháng.'
                                        : 'AXA Medical: ${injuredPlayers.map((p) => '#${p.number} ${p.name}').join(', ')} undergoing intensive treatment, excluded from contact training.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (expiringSoonPlayers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lfcYellow.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.lfcYellow.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: AppTheme.lfcYellow,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    state.isVietnamese
                                        ? 'Cảnh báo nhân sự: ${expiringSoonPlayers.length} cầu thủ sắp đáo hạn hợp đồng (${expiringSoonPlayers.map((p) => '#${p.number} ${p.name}').take(3).join(', ')}...). Ban quản trị cần rà soát điều khoản gia hạn.'
                                        : 'Contract Alert: ${expiringSoonPlayers.length} player(s) expiring soon (${expiringSoonPlayers.map((p) => '#${p.number} ${p.name}').take(3).join(', ')}...). Management renewal review required.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        if (topPlayer != null) ...[
                          Text(
                            state.tr('valuation_leader'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PlayerDetailScreen(player: topPlayer),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: topPlayer.isInjured
                                      ? AppTheme.danger.withValues(alpha: 0.7)
                                      : AppTheme.lfcYellow.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  PlayerAvatar(
                                    imageUrl: topPlayer.avatarUrl,
                                    radius: 32,
                                    initials: topPlayer.name[0],
                                    borderColor: topPlayer.isInjured
                                        ? AppTheme.danger
                                        : AppTheme.lfcYellow,
                                    borderWidth: 2,
                                    isInjured: topPlayer.isInjured,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.lfcYellow
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'TOP ASSET',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.lfcYellow,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              topPlayer.nationality,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '#${topPlayer.number} ${topPlayer.name}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          state.isVietnamese
                                              ? '${topPlayer.positionName} • Hợp đồng đến ${topPlayer.contractUntil}'
                                              : '${topPlayer.positionName} • Contract until ${topPlayer.contractUntil}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        state.isVietnamese ? 'Định giá' : 'Valuation',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      Text(
                                        '€${topPlayer.currentMarketValue.toStringAsFixed(0)}M',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.lfcYellow,
                                        ),
                                      ),
                                      const Text(
                                        'Transfermarkt',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.accentCyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        Text(
                          state.tr('squad_allocation'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    const Text(
                                      'Squad depth',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Total: €${state.totalMarketValue.toStringAsFixed(0)}M',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.lfcYellow,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                _buildPositionDepthBar(
                                  'Forwards',
                                  fwCount,
                                  25,
                                  fwVal,
                                  AppTheme.lfcRed,
                                ),
                                const SizedBox(height: 10),
                                _buildPositionDepthBar(
                                  'Midfielders',
                                  mfCount,
                                  25,
                                  mfVal,
                                  AppTheme.accentBlue,
                                ),
                                const SizedBox(height: 10),
                                _buildPositionDepthBar(
                                  'Defenders',
                                  dfCount,
                                  25,
                                  dfVal,
                                  AppTheme.accentCyan,
                                ),
                                const SizedBox(height: 10),
                                _buildPositionDepthBar(
                                  'Goalkeepers',
                                  gkCount,
                                  25,
                                  gkVal,
                                  AppTheme.lfcYellow,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              state.isVietnamese ? 'Cầu thủ tiêu biểu' : 'Key Squad Profiles',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              state.isVietnamese
                                  ? '${state.players.length} cầu thủ'
                                  : '${state.players.length} players',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Scroll left',
                              onPressed: () => _scrollSquad(-280),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            IconButton(
                              tooltip: 'Scroll right',
                              onPressed: () => _scrollSquad(280),
                              icon: const Icon(Icons.chevron_right),
                            ),
                            TextButton(
                              onPressed: () => widget.onNavigateTab(1),
                              child: Text(state.isVietnamese ? 'Xem tất cả' : 'All Players'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

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
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final p = state.players[index];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PlayerDetailScreen(player: p),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 136,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgCard,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.borderSubtle,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        PlayerAvatar(
                                          imageUrl: p.avatarUrl,
                                          radius: 26,
                                          initials: p.name.isNotEmpty
                                              ? p.name[0]
                                              : null,
                                          isInjured: p.isInjured,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          p.name,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '#${p.number} • ${p.position.name.toUpperCase()}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '€${p.currentMarketValue.toStringAsFixed(0)}M',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.lfcYellow,
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
                        const SizedBox(height: 20),

                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              state.isVietnamese
                                  ? 'Lịch tập luyện tại AXA Ground'
                                  : 'Upcoming Training Sessions at AXA',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.onNavigateTab(2),
                              child: Text(
                                state.isVietnamese ? 'Xem lịch tập' : 'View Calendar',
                                style: const TextStyle(
                                  color: AppTheme.lfcRed,
                                  fontSize: 13,
                                ),
                              ),
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
                                  color: AppTheme.lfcRed.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: AppTheme.lfcRed,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                session.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${session.startTime} - ${session.endTime} • ${session.location}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgCardLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  session.type,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
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
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Icon(icon, size: 16, color: color),
                Text(
                  '$count/$total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionDepthBar(
    String label,
    int count,
    int total,
    double val,
    Color color,
  ) {
    final pct = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              '$count players • €${val.toStringAsFixed(0)}M',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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
