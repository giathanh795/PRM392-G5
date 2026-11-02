import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../models/training_session.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_avatar.dart';
import '../player/player_detail_screen.dart';

/// Dashboard content uses the same provider data as the squad and commercial tabs.
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final players = state.players;
    final active = players.where((p) => p.status == 'Active').length;
    final injured = players.where((p) => p.status == 'Injured').length;
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
              _hero(activeCampaigns),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _openSquad(),
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('Manage squad'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.onNavigateTab(2),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Training schedule'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.onNavigateTab(3),
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Commercial report'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onManageData,
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Back up data'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _heading(
                'Club overview',
                'Based on current squad and training records',
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
                        'Total players',
                        '${players.length}',
                        '${players.map((p) => p.nationality).toSet().length} nationalities',
                        Icons.groups,
                        AppTheme.info,
                        () => _openSquad(),
                      ),
                      _metric(
                        width,
                        'Match ready',
                        '$active / ${players.length}',
                        '${(readiness * 100).toStringAsFixed(0)}% of squad · $injured injured',
                        Icons.health_and_safety_outlined,
                        AppTheme.success,
                        () => _showStatus(players),
                      ),
                      _metric(
                        width,
                        'Sessions on selected date',
                        '${sessions.length}',
                        DateFormat('dd/MM/yyyy').format(_date),
                        Icons.sports_soccer,
                        AppTheme.warning,
                        () => widget.onNavigateTab(2),
                      ),
                      _metric(
                        width,
                        'Squad market value',
                        _money(state.totalMarketValue),
                        change == null
                            ? 'No previous valuation available'
                            : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% vs. previous valuation',
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
                  'Training schedule',
                  'Select a date to explore the training plan',
                  Icons.event_note,
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
                            child: const Text('Today'),
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
                              child: const Text('First scheduled date'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (sessions.isEmpty)
                        _empty(
                          Icons.event_available,
                          'No sessions scheduled for this date.',
                          'Choose another date or view the first scheduled date.',
                        )
                      else
                        ...sessions.map(_session),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => widget.onNavigateTab(2),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Open training calendar'),
                      ),
                    ],
                  ),
                ),
                _panel(
                  'Squad availability',
                  'Player readiness and depth by position',
                  Icons.monitor_heart_outlined,
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
                          const Expanded(
                            child: Text(
                              'of players have Active status',
                              style: TextStyle(color: AppTheme.textSecondary),
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
                          _badge('$active ready', AppTheme.success),
                          _badge('$injured injured', AppTheme.danger),
                          _badge('$others other status', AppTheme.warning),
                        ],
                      ),
                      const Divider(height: 32, color: AppTheme.borderSubtle),
                      ...PlayerPosition.values.map((position) {
                        final count = players
                            .where((p) => p.position == position)
                            .length;
                        final labels = [
                          'Forwards',
                          'Midfielders',
                          'Defenders',
                          'Goalkeepers',
                        ];
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
                                    labels[position.index],
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
                        onPressed: () => _showStatus(players),
                        child: const Text('View availability details'),
                      ),
                    ],
                  ),
                ),
                _panel(
                  'Most valuable players',
                  'Top 5 by current market value · EUR millions',
                  Icons.workspace_premium_outlined,
                  Column(
                    children: [
                      if (ranked.isEmpty)
                        _empty(
                          Icons.person_search,
                          'No players available.',
                          'Add player data to view the rankings.',
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
                            ),
                          ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => widget.onNavigateTab(3),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('View all valuations'),
                        ),
                      ),
                    ],
                  ),
                ),
                _panel(
                  'Contract watch',
                  'Expired or expiring within the next 12 months',
                  Icons.description_outlined,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _badge(
                        '${expiring.length} contracts to review',
                        expiring.isEmpty ? AppTheme.success : AppTheme.warning,
                      ),
                      const SizedBox(height: 12),
                      if (expiring.isEmpty)
                        _empty(
                          Icons.verified_outlined,
                          'No contracts approaching expiry.',
                          'All dated contracts are outside the review window.',
                        )
                      else
                        ...expiring.take(3).map((p) {
                          final end = DateTime.parse(p.contractUntil);
                          return _playerRow(
                            p,
                            '#${p.number}',
                            DateFormat('dd/MM/yyyy').format(end),
                            end.isBefore(today) ? 'Expired' : 'Expiring soon',
                          );
                        }),
                      TextButton(
                        onPressed: () => _showContracts(expiring),
                        child: const Text('View contract list'),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              _panel(
                'Partners & campaigns',
                '$activeCampaigns campaigns with Active status',
                Icons.handshake_outlined,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.campaigns.isEmpty)
                      _empty(
                        Icons.campaign_outlined,
                        'No campaigns available.',
                        'Campaigns will appear here when data is available.',
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
                                  campaign.status,
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
                                  'Reach: ${campaign.reach}',
                                  style: const TextStyle(
                                    color: AppTheme.accentCyan,
                                  ),
                                ),
                                Text(
                                  'Engagement: ${campaign.engagement}',
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
                              'Players: ${campaign.featuredPlayerNames.join(', ')}',
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
                      label: const Text('Manage commercial & sponsorship'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Liverpool PMS · Overview of current application data',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(int campaigns) => Container(
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
            _badge('OPERATIONS CENTRE', AppTheme.accentCyan),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Your club at a glance',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your squad, training plans and commercial performance in one place.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
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
            _heroInfo(Icons.location_on_outlined, 'AXA Training Centre'),
            _heroInfo(Icons.campaign_outlined, '$campaigns active campaigns'),
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

  // Keep each column's gap fixed and align its bottom with the full-width panel.
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

  Widget _panel(String title, String subtitle, IconData icon, Widget child) =>
      Container(
        key: ValueKey('dashboard-panel-$title'),
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

  Widget _playerRow(Player player, String rank, String value, String detail) =>
      InkWell(
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
                      '$rank · ${player.positionName}',
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

  Widget _session(TrainingSession session) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(session.title),
          scrollable: true,
          content: Text(
            '${session.date} · ${session.startTime} – ${session.endTime}\n\n${session.location}\nCoach: ${session.coach}\n\n${session.description}\n\nStatus: ${session.status}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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
                _badge(session.type, AppTheme.warning),
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
              'Coach: ${session.coach} · ${session.status}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'View session details →',
              style: TextStyle(fontSize: 12, color: AppTheme.accentCyan),
            ),
          ],
        ),
      ),
    ),
  );

  void _showStatus(List<Player> players) {
    final unavailable = players.where((p) => p.status != 'Active').toList();
    _showPlayerList(
      'Unavailable players',
      unavailable,
      (p) => p.status,
      'All players currently have Active status.',
    );
  }

  void _showContracts(List<Player> players) => _showPlayerList(
    'Contracts to review',
    players,
    (p) => p.contractUntil,
    'No contracts expire within the review window.',
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
