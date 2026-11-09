import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
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

  String _positionBadge(PlayerPosition pos, bool isVi) {
    if (!isVi) return pos.name.toUpperCase();
    switch (pos) {
      case PlayerPosition.forward:
        return 'TIỀN ĐẠO';
      case PlayerPosition.midfielder:
        return 'TIỀN VỆ';
      case PlayerPosition.defender:
        return 'HẬU VỆ';
      case PlayerPosition.goalkeeper:
        return 'THỦ MÔN';
    }
  }

  String _footLabel(String foot, bool isVi) {
    if (!isVi) return 'Foot: $foot';
    final lower = foot.toLowerCase();
    if (lower == 'left') return 'Chân: Trái';
    if (lower == 'right') return 'Chân: Phải';
    if (lower == 'both') return 'Chân: Cả hai';
    return 'Chân: $foot';
  }

  @override
  Widget build(BuildContext context) {
    final isVi = context.watch<AppStateProvider>().isVietnamese;
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

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Hero(
                    tag: 'player_avatar_${player.id}',
                    child: PlayerAvatar(
                      imageUrl: player.avatarUrl,
                      radius: 28,
                      initials: player.name.isNotEmpty ? player.name[0] : null,
                    ),
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
                            _positionBadge(player.position, isVi),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: positionColor,
                            ),
                          ),
                        ),
                        if (player.isInjured) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.danger, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.medical_services_outlined, size: 9, color: AppTheme.danger),
                                const SizedBox(width: 2),
                                Text(
                                  isVi ? 'Chấn thương' : 'Injured',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.danger),
                                ),
                              ],
                            ),
                          ),
                        ] else if (player.isDoubtful) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.warning, width: 0.8),
                            ),
                            child: Text(
                              isVi ? 'Nghi ngờ' : 'Doubtful',
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.warning),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.nationality} • ${player.height} • ${_footLabel(player.preferredFoot, isVi)}',
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
                        if (player.isContractExpiringSoon) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.lfcYellow.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.lfcYellow.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 9, color: AppTheme.lfcYellow),
                                const SizedBox(width: 2),
                                Text(
                                  isVi
                                      ? 'HĐ ${player.contractUntil.split('-').first}'
                                      : 'EXP ${player.contractUntil.split('-').first}',
                                  style: const TextStyle(fontSize: 8, color: AppTheme.lfcYellow, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      color: AppTheme.textMuted,
                      tooltip: 'Chỉnh sửa cầu thủ',
                      splashRadius: 18,
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 2),
                  ],
                  if (onDelete != null) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppTheme.textMuted,
                      tooltip: 'Xóa cầu thủ',
                      splashRadius: 18,
                      onPressed: onDelete,
                    ),
                    const SizedBox(width: 2),
                  ],
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
