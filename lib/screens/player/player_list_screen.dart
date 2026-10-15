import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_card_item.dart';
import 'player_detail_screen.dart';

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final positions = ['All', 'Forward', 'Midfielder', 'Defender', 'Goalkeeper'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liverpool Squad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Player',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Player form modal ready for implementation')),
              );
            },
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
                  'Showing ${state.filteredPlayers.length} players',
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

          // Player List View
          Expanded(
            child: state.filteredPlayers.isEmpty
                ? const Center(
                    child: Text('No players found matching your criteria.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.builder(
                    itemCount: state.filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = state.filteredPlayers[index];
                      return PlayerCardItem(
                        player: player,
                        onTap: () {
                          context.read<AppStateProvider>().selectPlayer(player);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerDetailScreen(player: player),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
