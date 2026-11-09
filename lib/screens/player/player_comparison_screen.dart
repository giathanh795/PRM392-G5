import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/language_toggle_button.dart';

class PlayerComparisonScreen extends StatefulWidget {
  final Player? initialPlayer1;
  final Player? initialPlayer2;

  const PlayerComparisonScreen({
    super.key,
    this.initialPlayer1,
    this.initialPlayer2,
  });

  @override
  State<PlayerComparisonScreen> createState() => _PlayerComparisonScreenState();
}

class _PlayerComparisonScreenState extends State<PlayerComparisonScreen> {
  Player? _player1;
  Player? _player2;

  @override
  void initState() {
    super.initState();
    _player1 = widget.initialPlayer1;
    _player2 = widget.initialPlayer2;
  }

  void _showPlayerSelector(int slot, List<Player> allPlayers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Icon(
                    Icons.person_search,
                    color: slot == 1 ? AppTheme.accentCyan : AppTheme.lfcRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chọn cầu thủ so sánh #${slot == 1 ? "1" : "2"}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.borderSubtle),
            Expanded(
              child: ListView.separated(
                itemCount: allPlayers.length,
                separatorBuilder: (_, _) => const Divider(
                  color: AppTheme.borderSubtle,
                  height: 1,
                  indent: 64,
                ),
                itemBuilder: (context, index) {
                  final p = allPlayers[index];
                  final isSelected =
                      (slot == 1 && p.id == _player1?.id) ||
                      (slot == 2 && p.id == _player2?.id);
                  return ListTile(
                    leading: PlayerAvatar(
                      imageUrl: p.avatarUrl,
                      radius: 20,
                      initials: p.name.isNotEmpty ? p.name[0] : '?',
                    ),
                    title: Text(
                      '#${p.number} ${p.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (slot == 1 ? AppTheme.accentCyan : AppTheme.lfcRed)
                            : Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      '${p.positionName} • €${p.currentMarketValue.toStringAsFixed(0)}M • OVR: ${p.overallRating}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppTheme.accentCyan)
                        : null,
                    onTap: () {
                      setState(() {
                        if (slot == 1) {
                          _player1 = p;
                        } else {
                          _player2 = p;
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
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
    final allPlayers = state.players;

    if (_player1 == null && allPlayers.isNotEmpty) {
      _player1 = allPlayers.first;
    }
    if (_player2 == null && allPlayers.length > 1) {
      _player2 = allPlayers.length > 1 ? allPlayers[1] : allPlayers.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: Text(state.isVietnamese ? 'So sánh Cầu thủ Đối đầu' : 'Head-to-Head Comparison'),
        backgroundColor: AppTheme.surfaceNavy,
        actions: const [
          LanguageToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPlayerSelectorCard(
                    slot: 1,
                    player: _player1,
                    allPlayers: allPlayers,
                    color: AppTheme.accentCyan,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceNavyLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: AppTheme.lfcYellow,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildPlayerSelectorCard(
                    slot: 2,
                    player: _player2,
                    allPlayers: allPlayers,
                    color: AppTheme.lfcRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_player1 != null && _player2 != null) ...[
              _buildOverviewCard(_player1!, _player2!),
              const SizedBox(height: 16),
              _buildHeadToHeadAttributesCard(_player1!, _player2!),
              const SizedBox(height: 16),
              _buildPhysicalAndContractCard(_player1!, _player2!),
              const SizedBox(height: 16),
              _buildScoutingSummaryCard(_player1!, _player2!),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSelectorCard({
    required int slot,
    required Player? player,
    required List<Player> allPlayers,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showPlayerSelector(slot, allPlayers),
      child: Card(
        color: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            children: [
              if (player != null) ...[
                PlayerAvatar(
                  imageUrl: player.avatarUrl,
                  radius: 32,
                  initials: player.name.isNotEmpty ? player.name[0] : '?',
                  borderColor: color,
                  borderWidth: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  '#${player.number} ${player.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  player.position.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceNavyLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OVR: ${player.overallRating}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lfcYellow,
                    ),
                  ),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Chạm để chọn', style: TextStyle(color: AppTheme.textMuted)),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text('Đổi cầu thủ', style: TextStyle(fontSize: 10, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(Player p1, Player p2) {
    final diffVal = p1.currentMarketValue - p2.currentMarketValue;
    final diffOvr = p1.overallRating - p2.overallRating;

    return Card(
      color: AppTheme.surfaceNavy,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.query_stats, color: AppTheme.accentCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Tổng quan So sánh Giá trị & Đẳng cấp',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildComparisonMetricRow(
              title: 'Định giá thị trường',
              val1: '€${p1.currentMarketValue.toStringAsFixed(0)}M',
              val2: '€${p2.currentMarketValue.toStringAsFixed(0)}M',
              val1Num: p1.currentMarketValue,
              val2Num: p2.currentMarketValue,
              unit: 'M',
              delta: diffVal,
            ),
            const Divider(color: AppTheme.borderSubtle, height: 24),
            _buildComparisonMetricRow(
              title: 'Chỉ số tổng thể (OVR Rating)',
              val1: '${p1.overallRating}',
              val2: '${p2.overallRating}',
              val1Num: p1.overallRating.toDouble(),
              val2Num: p2.overallRating.toDouble(),
              unit: 'pts',
              delta: diffOvr.toDouble(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonMetricRow({
    required String title,
    required String val1,
    required String val2,
    required double val1Num,
    required double val2Num,
    required String unit,
    required double delta,
  }) {
    final p1Wins = val1Num > val2Num;
    final p2Wins = val2Num > val1Num;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              val1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: p1Wins ? AppTheme.accentCyan : Colors.white70,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              val2,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: p2Wins ? AppTheme.lfcRed : Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: max(1, val1Num.toInt()),
                child: Container(
                  height: 6,
                  color: p1Wins ? AppTheme.accentCyan : AppTheme.surfaceNavyLight,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: max(1, val2Num.toInt()),
                child: Container(
                  height: 6,
                  color: p2Wins ? AppTheme.lfcRed : AppTheme.surfaceNavyLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadToHeadAttributesCard(Player p1, Player p2) {
    final attrs1 = p1.latestAttributes;
    final attrs2 = p2.latestAttributes;
    final allKeys = {...attrs1.keys, ...attrs2.keys}.toList();

    return Card(
      color: AppTheme.surfaceNavy,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, color: AppTheme.lfcYellow, size: 20),
                SizedBox(width: 8),
                Text(
                  'Chi tiết Chỉ số Kỹ thuật Đối đầu',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (allKeys.isEmpty)
              const Text('Chưa có bộ chỉ số chi tiết để đối đầu.', style: TextStyle(color: AppTheme.textMuted))
            else
              ...allKeys.map((key) {
                final v1 = attrs1[key] ?? 70.0;
                final v2 = attrs2[key] ?? 70.0;
                final delta = (v1 - v2).toInt();

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 45,
                            child: Text(
                              v1.toInt().toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: v1 >= v2 ? AppTheme.accentCyan : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  key,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                if (delta != 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: delta > 0
                                          ? AppTheme.accentCyan.withValues(alpha: 0.15)
                                          : AppTheme.lfcRed.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      delta > 0 ? '+${delta.abs()}' : '-${delta.abs()}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: delta > 0 ? AppTheme.accentCyan : AppTheme.lfcRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 45,
                            child: Text(
                              v2.toInt().toString(),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: v2 >= v1 ? AppTheme.lfcRed : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 2,
                              child: LinearProgressIndicator(
                                value: (v1 / 100.0).clamp(0.0, 1.0),
                                backgroundColor: AppTheme.surfaceNavyLight,
                                color: AppTheme.accentCyan,
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (v2 / 100.0).clamp(0.0, 1.0),
                              backgroundColor: AppTheme.surfaceNavyLight,
                              color: AppTheme.lfcRed,
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalAndContractCard(Player p1, Player p2) {
    return Card(
      color: AppTheme.surfaceNavy,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center, color: AppTheme.accentCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Thể hình, Hợp đồng & Tình trạng Y tế',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildH2HDetailRow('Chiều cao', p1.height, p2.height),
            const Divider(color: AppTheme.borderSubtle, height: 16),
            _buildH2HDetailRow('Cân nặng', p1.weight, p2.weight),
            const Divider(color: AppTheme.borderSubtle, height: 16),
            _buildH2HDetailRow('Chân thuận', p1.preferredFoot, p2.preferredFoot),
            const Divider(color: AppTheme.borderSubtle, height: 16),
            _buildH2HDetailRow('Ngày sinh', p1.dateOfBirth, p2.dateOfBirth),
            const Divider(color: AppTheme.borderSubtle, height: 16),
            _buildH2HDetailRow('Hạn hợp đồng', p1.contractUntil, p2.contractUntil),
            const Divider(color: AppTheme.borderSubtle, height: 16),
            _buildH2HDetailRow(
              'Thể lực / Y tế',
              p1.isInjured ? 'Injured' : (p1.isDoubtful ? 'Doubtful' : 'Fit 100%'),
              p2.isInjured ? 'Injured' : (p2.isDoubtful ? 'Doubtful' : 'Fit 100%'),
              color1: p1.isInjured ? AppTheme.danger : (p1.isDoubtful ? AppTheme.warning : AppTheme.success),
              color2: p2.isInjured ? AppTheme.danger : (p2.isDoubtful ? AppTheme.warning : AppTheme.success),
            ),
            const Divider(color: AppTheme.borderSubtle, height: 16),
            _buildH2HDetailRow('Nhà tài trợ cá nhân', p1.sponsorPartner, p2.sponsorPartner),
          ],
        ),
      ),
    );
  }

  Widget _buildH2HDetailRow(String label, String val1, String val2, {Color? color1, Color? color2}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            val1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color1 ?? Colors.white,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        Expanded(
          child: Text(
            val2,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color2 ?? Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoutingSummaryCard(Player p1, Player p2) {
    int p1Wins = 0;
    int p2Wins = 0;
    final attrs1 = p1.latestAttributes;
    final attrs2 = p2.latestAttributes;
    final keys = {...attrs1.keys, ...attrs2.keys};

    for (final k in keys) {
      final v1 = attrs1[k] ?? 70.0;
      final v2 = attrs2[k] ?? 70.0;
      if (v1 > v2) p1Wins++;
      if (v2 > v1) p2Wins++;
    }

    String summary;
    if (p1Wins > p2Wins) {
      summary = '${p1.name} chiếm ưu thế ở $p1Wins/$keys.length chỉ số kỹ thuật, đặc biệt về thể chất và chỉ số phù hợp với lối chơi pressing tốc độ cao.';
    } else if (p2Wins > p1Wins) {
      summary = '${p2.name} chiếm ưu thế ở $p2Wins/$keys.length chỉ số kỹ thuật, thể hiện sự ổn định và điểm mạnh chiến thuật vượt trội.';
    } else {
      summary = 'Cả hai cầu thủ cân bằng tuyệt đối về mặt thông số, mang lại sự linh hoạt chiến thuật tuyệt vời cho ban huấn luyện Liverpool FC.';
    }

    return Card(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.lfcYellow, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.lfcYellow, size: 20),
                SizedBox(width: 8),
                Text(
                  'Đánh giá Tuyển trạch & Chiến thuật (Scouting Report)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.lfcYellow),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              summary,
              style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
