import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/player.dart';
import 'player_avatar.dart';

/// Hộp thoại xác nhận xóa cầu thủ với giao diện Liverpool FC
Future<bool?> showDeletePlayerConfirmationDialog(BuildContext context, Player player) {
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
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

      return AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.lfcRed.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lfcRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: AppTheme.lfcRed,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xác nhận xóa cầu thủ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'LFC Squad Management',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppTheme.borderSubtle, height: 1),
            const SizedBox(height: 16),
            // Thẻ tóm tắt thông tin cầu thủ cần xóa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceNavyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  PlayerAvatar(
                    imageUrl: player.avatarUrl,
                    radius: 24,
                    initials: player.name.isNotEmpty ? player.name[0] : '?',
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
                                player.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.lfcRed,
                                borderRadius: BorderRadius.circular(4),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: positionColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
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
                            const SizedBox(width: 6),
                            Text(
                              '${player.nationality} • €${player.currentMarketValue.toStringAsFixed(0)}M',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Bạn có chắc chắn muốn xóa "${player.name}" khỏi danh sách đội hình không?',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thao tác này sẽ xóa hồ sơ cầu thủ khỏi bộ nhớ máy. Bạn có thể nhấn Hoàn tác ngay sau khi xóa.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lfcRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text(
              'Xóa cầu thủ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
          ),
        ],
      );
    },
  );
}
