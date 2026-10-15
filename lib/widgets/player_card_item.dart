import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import 'player_avatar.dart';

class PlayerCardItem extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlayerCardItem({
    super.key,
    required this.player,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color positionColor;
    switch (player.position) {
      case PlayerPosition.forward:
        positionColor = AppTheme.lfcRed;
        break;
      case PlayerPosition.midfielder:
        positionColor = AppTheme.info;
        break;
      case PlayerPosition.defender:
        positionColor = AppTheme.warning;
        break;
      case PlayerPosition.goalkeeper:
        positionColor = AppTheme.lfcTeal;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Jersey Number Badge & Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  PlayerAvatar(
                    imageUrl: player.avatarUrl,
                    radius: 28,
                    initials: player.name.isNotEmpty ? player.name[0] : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.lfcRed,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '#${player.number}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: positionColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: positionColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            player.position.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: positionColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.nationality} • ${player.height} • Foot: ${player.preferredFoot}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '€${player.currentMarketValue.toStringAsFixed(0)}M',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lfcYellow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.adidasBlack,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: const Text(
                            'adidas',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Trailing action
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
