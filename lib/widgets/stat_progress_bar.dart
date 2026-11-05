// ============================================================================
// THANH TIẾN TRÌNH CHỈ SỐ KỸ NĂNG (STAT PROGRESS BAR WIDGET)
// ============================================================================
// Widget này dùng để trực quan hóa từng chỉ số kỹ năng đơn lẻ của cầu thủ
// (ví dụ: Tốc độ 91/100, Dứt điểm 88/100, Chuyền bóng 85/100...).
// Bao gồm:
// - Nhãn tên thuộc tính (label) bên trái.
// - Điểm số bằng số nguyên bên phải với màu sắc tương ứng.
// - Thanh tiến trình nằm ngang (LinearProgressIndicator) bo tròn góc.
// ============================================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatProgressBar extends StatelessWidget {
  /// Tên thuộc tính kỹ năng (Ví dụ: 'Tốc độ', 'Dứt điểm', 'Phòng ngự')
  final String label;

  /// Giá trị điểm số hiện tại của kỹ năng (Ví dụ: 85.0)
  final double value;

  /// Thang điểm tối đa để tính tỷ lệ phần trăm (Mặc định: 100.0)
  final double maxValue;

  /// Màu sắc hiển thị cho số điểm và thanh tiến trình (Mặc định: đỏ LFC)
  final Color barColor;

  const StatProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.maxValue = 100.0,
    this.barColor = AppTheme.lfcRed,
  });

  @override
  Widget build(BuildContext context) {
    // Chuẩn hóa tỷ lệ tiến trình nằm trong khoảng từ 0.0 đến 1.0
    final progress = (value / maxValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng tiêu đề hiển thị Tên chỉ số và Điểm số tương ứng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tên chỉ số (Nhãn)
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              // Điểm số dạng số nguyên (Làm tròn)
              Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Thanh tiến trình nằm ngang bo tròn các góc
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.bgCardLight,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
