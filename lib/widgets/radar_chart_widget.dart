// ============================================================================
// BIỂU ĐỒ MẠNG NHỆN CHỈ SỐ KỸ NĂNG (RADAR / SPIDER CHART WIDGET)
// ============================================================================
// Mục đích:
// - Vẽ biểu đồ đa giác mạng nhện trực quan hóa đồng thời tất cả các chỉ số
//   kỹ năng chính của cầu thủ (Tốc độ, Thể lực, Sút bóng, Chuyền bóng...).
// - Sử dụng CustomPainter vẽ thủ công trên Canvas để đạt hiệu năng tối đa.
// - Bao gồm:
//   + Lưới đa giác đồng tâm ở các mốc 25%, 50%, 75%, 100%.
//   + Các trục nan hoa tỏa ra từ tâm kèm nhãn tên và giá trị của chỉ số.
//   + Miền đa giác diện tích phủ dữ liệu thực tế kèm viền màu và chấm đỉnh.
// ============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RadarChartWidget extends StatelessWidget {
  /// Bộ thuộc tính kỹ năng dạng Map: {Tên thuộc tính: Điểm số}
  final Map<String, double> attributes;

  /// Thang điểm tối đa của biểu đồ (Mặc định: 100.0)
  final double maxValue;

  /// Màu đường viền đa giác dữ liệu (Mặc định: Đỏ LFC)
  final Color lineColor;

  /// Màu nền tô bên trong đa giác dữ liệu (Màu bán trong suốt)
  final Color fillColor;

  const RadarChartWidget({
    super.key,
    required this.attributes,
    this.maxValue = 100.0,
    this.lineColor = AppTheme.lfcRed,
    this.fillColor = const Color(0x55C8102E),
  });

  @override
  Widget build(BuildContext context) {
    // Nếu chưa có dữ liệu chỉ số, hiển thị thông báo trống
    if (attributes.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu chỉ số kỹ năng',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    // Tự động căn chỉnh kích thước vuông vức theo không gian hiển thị của màn hình
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RadarChartPainter(
                attributes: attributes,
                maxValue: maxValue,
                lineColor: lineColor,
                fillColor: fillColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lớp Painter chịu trách nhiệm vẽ các đường nét toán học của biểu đồ Radar
class _RadarChartPainter extends CustomPainter {
  final Map<String, double> attributes;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;

  _RadarChartPainter({
    required this.attributes,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Tọa độ tâm của biểu đồ
    final center = Offset(size.width / 2, size.height / 2);

    // Bán kính ngoài cùng (trừ đi 38px để chừa khoảng trống cho chữ nhãn hiển thị bên ngoài)
    final radius = min(size.width, size.height) / 2 - 38;
    final keys = attributes.keys.toList();
    final count = keys.length;

    // Biểu đồ đa giác cần tối thiểu 3 thuộc tính (tam giác) để hiển thị
    if (count < 3) return;

    // Bút vẽ lưới đa giác đồng tâm
    final gridPaint = Paint()
      ..color = AppTheme.borderSubtle.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Bút vẽ các trục nan hoa nối từ tâm ra các đỉnh
    final axisPaint = Paint()
      ..color = AppTheme.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // ------------------------------------------------------------------------
    // 1. VẼ CÁC VÒNG LƯỚI ĐA GIÁC ĐỒNG TÂM (Tương ứng các mốc 25%, 50%, 75%, 100%)
    // ------------------------------------------------------------------------
    const levels = 4;
    for (int lvl = 1; lvl <= levels; lvl++) {
      final currentRadius = radius * (lvl / levels);
      final gridPath = Path();
      for (int i = 0; i < count; i++) {
        // Góc nghiêng theo hệ tọa độ cực (Trừ pi/2 để đỉnh đầu tiên hướng thẳng lên 12h)
        final angle = (2 * pi / count) * i - pi / 2;
        final x = center.dx + currentRadius * cos(angle);
        final y = center.dy + currentRadius * sin(angle);
        if (i == 0) {
          gridPath.moveTo(x, y);
        } else {
          gridPath.lineTo(x, y);
        }
      }
      gridPath.close();
      canvas.drawPath(gridPath, gridPaint);
    }

    // ------------------------------------------------------------------------
    // 2. VẼ CÁC TRỤC NAN HOA VÀ NHÃN VĂN BẢN (Tên chỉ số + Điểm số)
    // ------------------------------------------------------------------------
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i - pi / 2;
      final endX = center.dx + radius * cos(angle);
      final endY = center.dy + radius * sin(angle);

      // Kẻ đường nối từ tâm đến đỉnh ngoài cùng
      canvas.drawLine(center, Offset(endX, endY), axisPaint);

      // Nhãn tên chỉ số và giá trị điểm hiển thị ở phía ngoài đa giác
      final key = keys[i];
      final val = attributes[key] ?? 0;
      final label = '$key\n${val.toInt()}';

      // Khoảng cách từ tâm đến vị trí đặt văn bản
      final labelDist = radius + 22;
      final labelX = center.dx + labelDist * cos(angle);
      final labelY = center.dy + labelDist * sin(angle);

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      );
      textPainter.layout();
      // Vẽ chữ căn giữa điểm tính toán
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // ------------------------------------------------------------------------
    // 3. VẼ ĐA GIÁC BIỂU DIỄN CHỈ SỐ THỰC TẾ CỦA CẦU THỦ
    // ------------------------------------------------------------------------
    final dataPath = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi / count) * i - pi / 2;
      final val = attributes[keys[i]] ?? 0.0;
      // Chuẩn hóa điểm số về khoảng [0.0, 1.0]
      final normalized = (val / maxValue).clamp(0.0, 1.0);
      final curRadius = radius * normalized;
      final x = center.dx + curRadius * cos(angle);
      final y = center.dy + curRadius * sin(angle);
      final point = Offset(x, y);
      dataPoints.add(point);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Bước 3.1: Tô màu miền diện tích bên trong đa giác
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Bước 3.2: Vẽ đường viền đỏ đậm quanh đa giác
    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(dataPath, strokePaint);

    // Bước 3.3: Vẽ các chấm tròn màu vàng tại mỗi đỉnh chỉ số
    final dotPaint = Paint()..color = AppTheme.lfcYellow;
    for (final pt in dataPoints) {
      canvas.drawCircle(pt, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    // Chỉ vẽ lại khi các giá trị chỉ số hoặc màu sắc có sự thay đổi
    return oldDelegate.attributes != attributes ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
