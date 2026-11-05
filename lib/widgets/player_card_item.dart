// ============================================================================
// THẺ CẦU THỦ TRONG DANH SÁCH (PLAYER CARD ITEM WIDGET)
// ============================================================================
// Mục đích:
// - Hiển thị tóm tắt thông tin của một cầu thủ dưới dạng thẻ Card trong danh sách:
//   1. Ảnh đại diện kết hợp số áo thi đấu (#number) ở góc dưới.
//   2. Họ tên cầu thủ, huy hiệu vị trí thi đấu (FW, MF, DF, GK) theo dải màu nhận diện.
//   3. Quốc tịch, chiều cao, chân thuận.
//   4. Định giá thị trường chuyển nhượng hiện tại (€...M) và nhãn nhà tài trợ cá nhân.
//   5. Cụm nút hành động: Sửa (onEdit), Xóa (onDelete) và Mũi tên chuyển trang chi tiết (onTap).
// ============================================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import 'player_avatar.dart';

class PlayerCardItem extends StatelessWidget {
  /// Đối tượng cầu thủ cần hiển thị thông tin
  final Player player;

  /// Hàm callback kích hoạt khi người dùng nhấn vào thẻ (mở màn hình chi tiết)
  final VoidCallback onTap;

  /// Hàm callback kích hoạt khi nhấn nút Chỉnh sửa (mở Form cập nhật)
  final VoidCallback? onEdit;

  /// Hàm callback kích hoạt khi nhấn nút Xóa (mở hộp thoại xác nhận xóa)
  final VoidCallback? onDelete;

  /// --------------------------------------------------------------------------
  /// HÀM KHỞI TẠO (CONSTRUCTOR) CỦA PLAYER CARD ITEM
  /// Đóng vai trò làm "cổng nhận dữ liệu & hành động" từ màn hình danh sách (PlayerListScreen):
  /// - super.key: Khóa định danh của Widget trong cây giao diện Flutter.
  /// - player: Thông tin đối tượng cầu thủ cần hiển thị lên thẻ (Bắt buộc).
  /// - onTap: Hành động kích hoạt khi chạm vào thẻ để xem chi tiết (Bắt buộc).
  /// - onEdit: Hành động kích hoạt khi nhấn nút Sửa (icon cây bút) để mở form sửa (Tùy chọn).
  /// - onDelete: Hành động kích hoạt khi nhấn nút Xóa (icon thùng rác) để mở dialog xác nhận (Tùy chọn).
  /// --------------------------------------------------------------------------
  const PlayerCardItem({
    super.key,
    required this.player,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------------------
    // Xác định màu sắc đại diện cho từng tuyến vị trí thi đấu
    // - Tiền đạo (Forward): Màu đỏ truyền thống Liverpool FC
    // - Tiền vệ (Midfielder): Màu xanh dương năng động
    // - Hậu vệ (Defender): Màu vàng cam cảnh giác
    // - Thủ môn (Goalkeeper): Màu xanh ngọc độc đáo
    // ------------------------------------------------------------------------
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
              // --------------------------------------------------------------
              // 1. CỤM ẢNH ĐẠI DIỆN KÈM HUY HIỆU SỐ ÁO THI ĐẤU
              // --------------------------------------------------------------
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  PlayerAvatar(
                    imageUrl: player.avatarUrl,
                    radius: 28,
                    initials: player.name.isNotEmpty ? player.name[0] : null,
                  ),
                  // Huy hiệu số áo nổi bật ở góc dưới bên phải avatar
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

              // --------------------------------------------------------------
              // 2. CỤM THÔNG TIN CÁ NHÂN VÀ ĐỊNH GIÁ CHUYỂN NHƯỢNG
              // --------------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dòng tên cầu thủ và nhãn vị trí thi đấu
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
                        // Nhãn vị trí thi đấu có màu nền đồng bộ
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

                    // Quốc tịch, chiều cao, chân thuận
                    Text(
                      '${player.nationality} • ${player.height} • Foot: ${player.preferredFoot}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),

                    // Định giá chuyển nhượng và logo nhà tài trợ
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

              // --------------------------------------------------------------
              // 3. CỤM NÚT THAO TÁC NHANH (SỬA, XÓA, XEM CHI TIẾT)
              // --------------------------------------------------------------
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút Sửa thông tin cầu thủ
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
                  // Nút Xóa cầu thủ
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
                  // Mũi tên chỉ dẫn điều hướng sang chi tiết
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
