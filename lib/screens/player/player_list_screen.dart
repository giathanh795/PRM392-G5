import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_card_item.dart';
import '../../widgets/delete_player_dialog.dart';
import 'player_detail_screen.dart';

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  Future<void> _handleDeletePlayer(BuildContext context, Player player) async {
    final confirmed = await showDeletePlayerConfirmationDialog(context, player);
    if (confirmed == true && context.mounted) {
      final originalIndex = context.read<AppStateProvider>().players.indexWhere((p) => p.id == player.id);
      final deleted = await context.read<AppStateProvider>().deletePlayer(player.id);
      if (context.mounted && deleted != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.surfaceNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã xóa cầu thủ "${player.name}"',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'HOÀN TÁC',
              textColor: AppTheme.lfcYellow,
              onPressed: () {
                context.read<AppStateProvider>().restorePlayer(
                  originalIndex >= 0 ? originalIndex : 0,
                  deleted,
                );
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showResetConfirmation(BuildContext context) {
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
            Icon(Icons.restart_alt_rounded, color: AppTheme.lfcYellow, size: 24),
            SizedBox(width: 8),
            Text('Khôi phục danh sách', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn có muốn đặt lại toàn bộ danh sách 25 cầu thủ Liverpool FC về trạng thái mặc định ban đầu không?',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
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
              Navigator.of(dialogCtx).pop();
              await context.read<AppStateProvider>().resetToDefaultMockData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã khôi phục toàn bộ danh sách 25 cầu thủ Liverpool FC!'),
                  ),
                );
              }
            },
            child: const Text('Khôi phục ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final positions = ['All', 'Forward', 'Midfielder', 'Defender', 'Goalkeeper'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liverpool Squad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Khôi phục danh sách gốc',
            onPressed: () => _showResetConfirmation(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search player by name, number, nationality...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () => context.read<AppStateProvider>().setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: (val) => context.read<AppStateProvider>().setSearchQuery(val),
            ),
          ),

          // Position Filter Horizontal Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: positions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final pos = positions[index];
                final isSelected = state.selectedPositionFilter.toLowerCase() == pos.toLowerCase();

                return ChoiceChip(
                  label: Text(pos),
                  selected: isSelected,
                  selectedColor: AppTheme.lfcRed,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => context.read<AppStateProvider>().setPositionFilter(pos),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Total Count Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị ${state.filteredPlayers.length} cầu thủ',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const Row(
                  children: [
                    Icon(Icons.shield, size: 14, color: AppTheme.lfcRed),
                    SizedBox(width: 4),
                    Text('LFC Official Roster', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // Player List View with Dismissible & Delete Action
          Expanded(
            child: state.filteredPlayers.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy cầu thủ phù hợp.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.builder(
                    itemCount: state.filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = state.filteredPlayers[index];
                      return Dismissible(
                        key: ValueKey('player_${player.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.lfcRed.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Xóa cầu thủ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDeletePlayerConfirmationDialog(context, player);
                        },
                        onDismissed: (direction) async {
                          final originalIndex = context.read<AppStateProvider>().players.indexWhere((p) => p.id == player.id);
                          final deleted = await context.read<AppStateProvider>().deletePlayer(player.id);
                          if (context.mounted && deleted != null) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppTheme.surfaceNavy,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: AppTheme.borderSubtle),
                                ),
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: AppTheme.accentCyan, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Đã xóa cầu thủ "${player.name}"',
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                action: SnackBarAction(
                                  label: 'HOÀN TÁC',
                                  textColor: AppTheme.lfcYellow,
                                  onPressed: () {
                                    context.read<AppStateProvider>().restorePlayer(
                                      originalIndex >= 0 ? originalIndex : 0,
                                      deleted,
                                    );
                                  },
                                ),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                        child: PlayerCardItem(
                          player: player,
                          onTap: () {
                            context.read<AppStateProvider>().selectPlayer(player);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerDetailScreen(player: player),
                              ),
                            );
                          },
                          onDelete: () => _handleDeletePlayer(context, player),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
