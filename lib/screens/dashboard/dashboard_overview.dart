import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../models/training_session.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_avatar.dart';
import '../player/player_detail_screen.dart';

class DashboardOverview extends StatefulWidget {
  final AppStateProvider state;
  final ValueChanged<int> onNavigateTab;
  final VoidCallback onManageData;

  const DashboardOverview({
    super.key,
    required this.state,
    required this.onNavigateTab,
    required this.onManageData,
  });

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());

  void _openSquad([PlayerPosition? position]) {
    widget.state.setSearchQuery('');
    widget.state.setPositionFilter(position?.name ?? 'All');
    widget.onNavigateTab(1);
  }

  void _openPlayer(Player player) {
    widget.state.selectPlayer(player);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerDetailScreen(player: player),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  String _posLabel(PlayerPosition pos, bool isVi) {
    if (!isVi) {
      return switch (pos) {
        PlayerPosition.forward => 'Forwards',
        PlayerPosition.midfielder => 'Midfielders',
        PlayerPosition.defender => 'Defenders',
        PlayerPosition.goalkeeper => 'Goalkeepers',
      };
    }
    return switch (pos) {
      PlayerPosition.forward => 'Tiền đạo',
      PlayerPosition.midfielder => 'Tiền vệ',
      PlayerPosition.defender => 'Hậu vệ',
      PlayerPosition.goalkeeper => 'Thủ môn',
    };
  }

  String _posSingleVi(PlayerPosition pos, bool isVi) {
    if (!isVi) {
      return switch (pos) {
        PlayerPosition.forward => 'Forward',
        PlayerPosition.midfielder => 'Midfielder',
        PlayerPosition.defender => 'Defender',
        PlayerPosition.goalkeeper => 'Goalkeeper',
      };
    }
    return switch (pos) {
      PlayerPosition.forward => 'Tiền đạo',
      PlayerPosition.midfielder => 'Tiền vệ',
      PlayerPosition.defender => 'Hậu vệ',
      PlayerPosition.goalkeeper => 'Thủ môn',
    };
  }

  String _sessionTypeLabel(String type, bool isVi) {
    if (!isVi) return type;
    return switch (type) {
      'Gym' => 'Thể lực',
      'Tactical' => 'Chiến thuật',
      'Recovery' => 'Hồi phục',
      'Match Prep' => 'Chuẩn bị trận',
      _ => type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isVi = state.isVietnamese;
    final players = state.players;
    final active = players.where((p) => p.status == 'Active').length;
    final injured = players.where((p) => p.isInjured).length;
    final others = players.length - active - injured;
    final readiness = players.isEmpty ? 0.0 : active / players.length;
    final dateKey = DateFormat('yyyy-MM-dd').format(_date);
    final sessions = state.trainings.where((t) => t.date == dateKey).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final ranked = List<Player>.of(players)
      ..sort((a, b) => b.currentMarketValue.compareTo(a.currentMarketValue));
    final previous = players.fold(0.0, (sum, p) => sum + p.previousMarketValue);
    final change = previous == 0
        ? null
        : (state.totalMarketValue - previous) / previous * 100;
    final activeCampaigns = state.campaigns
        .where((c) => c.status == 'Active')
        .length;
    final today = DateUtils.dateOnly(DateTime.now());
    final contractLimit = DateTime(today.year + 1, today.month, today.day);
    final expiring = players.where((p) {
      final end = DateTime.tryParse(p.contractUntil);
      return end != null && !end.isAfter(contractLimit);
    }).toList()..sort((a, b) => a.contractUntil.compareTo(b.contractUntil));

    return SingleChildScrollView(
      key: const PageStorageKey('dashboard-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(activeCampaigns, isVi),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _openSquad(),
                    icon: const Icon(Icons.groups_outlined),
                    label: Text(isVi ? 'Quản lý đội hình' : 'Manage squad'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.onNavigateTab(2),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(isVi ? 'Lịch trình huấn luyện' : 'Training schedule'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.onNavigateTab(3),
                    icon: const Icon(Icons.trending_up),
                    label: Text(isVi ? 'Báo cáo thương mại' : 'Commercial report'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onManageData,
                    icon: const Icon(Icons.backup_outlined),
                    label: Text(isVi ? 'Sao lưu dữ liệu' : 'Back up data'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _heading(
                isVi ? 'Tổng quan CLB' : 'Club overview',
                isVi
                    ? 'Dựa trên dữ liệu đội hình và hồ sơ huấn luyện hiện tại'
                    : 'Based on current squad and training records',
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 4
                      : constraints.maxWidth >= 320
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _metric(
                        width,
                        isVi ? 'Tổng số cầu thủ' : 'Total players',
                        '${players.length}',
                        isVi
                            ? '${players.map((p) => p.nationality).toSet().length} quốc tịch'
                            : '${players.map((p) => p.nationality).toSet().length} nationalities',
                        Icons.groups,
                        AppTheme.info,
                        () => _openSquad(),
                      ),
                      _metric(
                        width,
                        isVi ? 'Sẵn sàng thi đấu' : 'Match ready',
                        '$active / ${players.length}',
                        isVi
                            ? '${(readiness * 100).toStringAsFixed(0)}% đội hình · $injured chấn thương'
                            : '${(readiness * 100).toStringAsFixed(0)}% of squad · $injured injured',
                        Icons.health_and_safety_outlined,
                        AppTheme.success,
                        () => _showStatus(players, isVi),
                      ),
                      _metric(
                        width,
                        isVi ? 'Buổi tập ngày đã chọn' : 'Sessions on selected date',
                        '${sessions.length}',
                        DateFormat('dd/MM/yyyy').format(_date),
                        Icons.sports_soccer,
                        AppTheme.warning,
                        () => widget.onNavigateTab(2),
                      ),
                      _metric(
                        width,
                        isVi ? 'Giá trị chuyển nhượng' : 'Squad market value',
                        _money(state.totalMarketValue),
                        change == null
                            ? (isVi
                                ? 'Chưa có định giá trước'
                                : 'No previous valuation available')
                            : (isVi
                                ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% so với kỳ trước'
                                : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% vs. previous valuation'),
                        Icons.account_balance_wallet_outlined,
                        AppTheme.lfcYellow,
                        () => widget.onNavigateTab(3),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _panelGrid([
                _panel(
                  isVi ? 'Lịch trình huấn luyện' : 'Training schedule',
                  isVi
                      ? 'Chọn ngày để xem chi tiết giáo án tập luyện'
                      : 'Select a date to explore the training plan',
                  Icons.event_note,
                  'Training schedule',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(DateFormat('dd/MM/yyyy').format(_date)),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _date = today),
                            child: Text(isVi ? 'Hôm nay' : 'Today'),
                          ),
                          if (state.trainings.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                final dates =
                                    state.trainings
                                        .map((t) => DateTime.tryParse(t.date))
                                        .whereType<DateTime>()
                                        .toList()
                                      ..sort();
                                if (dates.isNotEmpty) {
                                  setState(() => _date = dates.first);
                                }
                              },
                              child: Text(
                                isVi ? 'Ngày tập đầu tiên' : 'First scheduled date',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (sessions.isEmpty)
                        _empty(
                          Icons.event_available,
                          isVi
                              ? 'Không có buổi tập nào trong ngày này.'
                              : 'No sessions scheduled for this date.',
                          isVi
                              ? 'Hãy chọn ngày khác hoặc xem ngày tập đầu tiên.'
                              : 'Choose another date or view the first scheduled date.',
                        )
                      else
                        ...sessions.map((s) => _session(s, isVi)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => widget.onNavigateTab(2),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text(
                          isVi
                              ? 'Mở lịch huấn luyện toàn diện'
                              : 'Open training calendar',
                        ),
                      ),
                    ],
                  ),
                ),
                _panel(
                  isVi ? 'Tình trạng sẵn sàng đội hình' : 'Squad availability',
                  isVi
                      ? 'Mức độ sẵn sàng và chiều sâu từng vị trí'
                      : 'Player readiness and depth by position',
                  Icons.monitor_heart_outlined,
                  'Squad availability',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${(readiness * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isVi
                                  ? 'cầu thủ ở trạng thái Sẵn sàng'
                                  : 'of players have Active status',
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: readiness,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.accentCyan,
                        backgroundColor: AppTheme.surfaceNavyLight,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _badge(
                            isVi ? '$active sẵn sàng' : '$active ready',
                            AppTheme.success,
                          ),
                          _badge(
                            isVi ? '$injured chấn thương' : '$injured injured',
                            AppTheme.danger,
                          ),
                          _badge(
                            isVi ? '$others trạng thái khác' : '$others other status',
                            AppTheme.warning,
                          ),
                        ],
                      ),
                      const Divider(height: 32, color: AppTheme.borderSubtle),
                      ...PlayerPosition.values.map((position) {
                        final count = players
                            .where((p) => p.position == position)
                            .length;
                        return InkWell(
                          onTap: () => _openSquad(position),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 104,
                                  child: Text(
                                    _posLabel(position, isVi),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: players.isEmpty
                                        ? 0
                                        : count / players.length,
                                    color: AppTheme.info,
                                    backgroundColor: AppTheme.surfaceNavyLight,
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('$count'),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppTheme.textMuted,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      TextButton(
                        onPressed: () => _showStatus(players, isVi),
                        child: Text(
                          isVi
                              ? 'Xem chi tiết tình trạng cầu thủ'
                              : 'View availability details',
                        ),
                      ),
                    ],
                  ),
                ),
                _panel(
                  isVi ? 'Cầu thủ giá trị cao nhất' : 'Most valuable players',
                  isVi
                      ? 'Top 5 theo giá trị thị trường · Triệu EUR'
                      : 'Top 5 by current market value · EUR millions',
                  Icons.workspace_premium_outlined,
                  'Most valuable players',
                  Column(
                    children: [
                      if (ranked.isEmpty)
                        _empty(
                          Icons.person_search,
                          isVi
                              ? 'Chưa có cầu thủ nào.'
                              : 'No players available.',
                          isVi
                              ? 'Thêm dữ liệu cầu thủ để xem xếp hạng.'
                              : 'Add player data to view the rankings.',
                        ),
                      ...ranked
                          .take(5)
                          .indexed
                          .map(
                            (entry) => _playerRow(
                              entry.$2,
                              '${entry.$1 + 1}',
                              _money(entry.$2.currentMarketValue),
                              '${entry.$2.marketValueChangePercent >= 0 ? '+' : ''}${entry.$2.marketValueChangePercent.toStringAsFixed(1)}%',
                              isVi,
                            ),
                          ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => widget.onNavigateTab(3),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: Text(
                            isVi ? 'Xem tất cả định giá' : 'View all valuations',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _panel(
                  isVi ? 'Theo dõi thời hạn hợp đồng' : 'Contract watch',
                  isVi
                      ? 'Đã hết hạn hoặc hết hạn trong 12 tháng tới'
                      : 'Expired or expiring within the next 12 months',
                  Icons.description_outlined,
                  'Contract watch',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _badge(
                        isVi
                            ? '${expiring.length} hợp đồng cần xem xét'
                            : '${expiring.length} contracts to review',
                        expiring.isEmpty ? AppTheme.success : AppTheme.warning,
                      ),
                      const SizedBox(height: 12),
                      if (expiring.isEmpty)
                        _empty(
                          Icons.verified_outlined,
                          isVi
                              ? 'Không có hợp đồng nào sắp hết hạn.'
                              : 'No contracts approaching expiry.',
                          isVi
                              ? 'Tất cả hợp đồng đều còn thời hạn dài.'
                              : 'All dated contracts are outside the review window.',
                        )
                      else
                        ...expiring.take(3).map((p) {
                          final end = DateTime.parse(p.contractUntil);
                          return _playerRow(
                            p,
                            '#${p.number}',
                            DateFormat('dd/MM/yyyy').format(end),
                            end.isBefore(today)
                                ? (isVi ? 'Đã hết hạn' : 'Expired')
                                : (isVi ? 'Sắp hết hạn' : 'Expiring soon'),
                            isVi,
                          );
                        }),
                      TextButton(
                        onPressed: () => _showContracts(expiring, isVi),
                        child: Text(
                          isVi
                              ? 'Xem danh sách hợp đồng'
                              : 'View contract list',
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              _panel(
                isVi ? 'Đối tác & Chiến dịch' : 'Partners & campaigns',
                isVi
                    ? '$activeCampaigns chiến dịch đang hoạt động'
                    : '$activeCampaigns campaigns with Active status',
                Icons.handshake_outlined,
                'Partners & campaigns',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.campaigns.isEmpty)
                      _empty(
                        Icons.campaign_outlined,
                        isVi
                            ? 'Chưa có chiến dịch nào.'
                            : 'No campaigns available.',
                        isVi
                            ? 'Chiến dịch sẽ hiển thị tại đây khi có dữ liệu.'
                            : 'Campaigns will appear here when data is available.',
                      ),
                    ...state.campaigns.map(
                      (campaign) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _badge(
                                  campaign.sponsorName,
                                  AppTheme.lfcYellow,
                                ),
                                _badge(
                                  isVi
                                      ? (campaign.status == 'Active'
                                          ? 'Đang chạy'
                                          : campaign.status)
                                      : campaign.status,
                                  campaign.status == 'Active'
                                      ? AppTheme.success
                                      : AppTheme.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              campaign.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              campaign.description,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 20,
                              runSpacing: 8,
                              children: [
                                Text(
                                  isVi
                                      ? 'Tiếp cận: ${campaign.reach}'
                                      : 'Reach: ${campaign.reach}',
                                  style: const TextStyle(
                                    color: AppTheme.accentCyan,
                                  ),
                                ),
                                Text(
                                  isVi
                                      ? 'Tương tác: ${campaign.engagement}'
                                      : 'Engagement: ${campaign.engagement}',
                                  style: const TextStyle(
                                    color: AppTheme.lfcYellow,
                                  ),
                                ),
                                Text(
                                  '${campaign.startDate} → ${campaign.endDate}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isVi
                                  ? 'Cầu thủ tham gia: ${campaign.featuredPlayerNames.join(', ')}'
                                  : 'Players: ${campaign.featuredPlayerNames.join(', ')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => widget.onNavigateTab(3),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(
                        isVi
                            ? 'Quản lý thương mại & tài trợ'
                            : 'Manage commercial & sponsorship',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isVi
                    ? 'Liverpool FC - Hệ thống Quản lý Cầu thủ · Tổng quan dữ liệu thời gian thực'
                    : 'Liverpool FC - Player Management System · Overview of current application data',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(int campaigns, bool isVi) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        colors: [Color(0xFF17395C), AppTheme.surfaceNavy],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: AppTheme.borderSubtle),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _badge('LIVERPOOL FC', AppTheme.lfcRed),
            _badge(
              isVi ? 'TRUNG TÂM ĐIỀU HÀNH' : 'OPERATIONS CENTRE',
              AppTheme.accentCyan,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          isVi ? 'Toàn cảnh Câu lạc bộ' : 'Your club at a glance',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isVi
              ? 'Theo dõi đội hình, kế hoạch huấn luyện và hiệu suất thương mại tại một nơi tập trung.'
              : 'Track your squad, training plans and commercial performance in one place.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _heroInfo(
              Icons.today_outlined,
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
            ),
            _heroInfo(
              Icons.location_on_outlined,
              isVi ? 'Trung tâm HL AXA' : 'AXA Training Centre',
            ),
            _heroInfo(
              Icons.campaign_outlined,
              isVi
                  ? '$campaigns chiến dịch đang chạy'
                  : '$campaigns active campaigns',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _heroInfo(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppTheme.accentCyan),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
    ],
  );

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    ),
  );

  Widget _metric(
    double width,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => SizedBox(
    width: width,
    child: Material(
      color: AppTheme.surfaceNavy,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 25,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _panelGrid(List<Widget> panels) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 850) {
        return Column(
          children: [
            for (var i = 0; i < panels.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              panels[i],
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                panels[0],
                const SizedBox(height: 20),
                panels[2],
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                panels[1],
                const SizedBox(height: 20),
                panels[3],
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _panel(
    String title,
    String subtitle,
    IconData icon,
    String panelKey,
    Widget child,
  ) => Container(
    key: ValueKey('dashboard-panel-$panelKey'),
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTheme.surfaceNavy,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.borderSubtle),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accentCyan, size: 22),
            const SizedBox(width: 10),
            Expanded(child: _heading(title, subtitle)),
          ],
        ),
        child,
      ],
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _empty(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 30, color: AppTheme.textMuted),
        const SizedBox(height: 10),
        Text(title),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _playerRow(
    Player player,
    String rank,
    String value,
    String detail,
    bool isVi,
  ) => InkWell(
    onTap: () => _openPlayer(player),
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          PlayerAvatar(
            imageUrl: player.avatarUrl,
            radius: 20,
            initials: player.name.isEmpty ? '?' : player.name[0],
            isInjured: player.isInjured,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$rank · ${_posSingleVi(player.position, isVi)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value · $detail',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.lfcYellow,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppTheme.textMuted,
          ),
        ],
      ),
    ),
  );

  Widget _session(TrainingSession session, bool isVi) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(session.title),
          scrollable: true,
          content: Text(
            isVi
                ? '${session.date} · ${session.startTime} – ${session.endTime}\n\n${session.location}\nHLV: ${session.coach}\n\n${session.description}\n\nTrạng thái: ${session.status == 'Completed' ? 'Đã hoàn thành' : 'Kế hoạch'}'
                : '${session.date} · ${session.startTime} – ${session.endTime}\n\n${session.location}\nCoach: ${session.coach}\n\n${session.description}\n\nStatus: ${session.status}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isVi ? 'Đóng' : 'Close'),
            ),
          ],
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _badge(
                  '${session.startTime} – ${session.endTime}',
                  AppTheme.accentCyan,
                ),
                _badge(
                  _sessionTypeLabel(session.type, isVi),
                  AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              session.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              session.location,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isVi
                  ? 'HLV: ${session.coach} · ${session.status == 'Completed' ? 'Đã hoàn thành' : 'Kế hoạch'}'
                  : 'Coach: ${session.coach} · ${session.status}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVi ? 'Xem chi tiết buổi tập →' : 'View session details →',
              style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan),
            ),
          ],
        ),
      ),
    ),
  );

  void _showStatus(List<Player> players, bool isVi) {
    final unavailable = players.where((p) => p.status != 'Active').toList();
    _showPlayerList(
      isVi ? 'Cầu thủ chưa sẵn sàng' : 'Unavailable players',
      unavailable,
      (p) => isVi ? (p.status == 'Injured' ? 'Chấn thương' : p.status) : p.status,
      isVi
          ? 'Tất cả cầu thủ hiện đều ở trạng thái Sẵn sàng.'
          : 'All players currently have Active status.',
    );
  }

  void _showContracts(List<Player> players, bool isVi) => _showPlayerList(
    isVi ? 'Hợp đồng cần xem xét' : 'Contracts to review',
    players,
    (p) => p.contractUntil,
    isVi
        ? 'Không có hợp đồng nào hết hạn trong kỳ xem xét.'
        : 'No contracts expire within the review window.',
  );

  void _showPlayerList(
    String title,
    List<Player> players,
    String Function(Player) subtitle,
    String empty,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: players.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(empty),
                        ),
                      )
                    : ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (_, index) {
                          final player = players[index];
                          return ListTile(
                            title: Text(player.name),
                            subtitle: Text(subtitle(player)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _openPlayer(player);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _money(double value) => '€${value.toStringAsFixed(1)}M';
}
