// ============================================================================
// WIDGET HIỂN THỊ ẢNH ĐẠI DIỆN CẦU THỦ (PLAYER AVATAR WIDGET)
// ============================================================================
// Mục đích:
// - Hiển thị ảnh đại diện dạng hình tròn (Circle Avatar) với viền tùy biến.
// - Tự động nhận diện và xử lý đa dạng mọi nguồn ảnh:
//   1. Ảnh Base64 Data URI ('data:image/...'): Đọc trực tiếp từ bộ nhớ byte (hỗ trợ offline vĩnh viễn trên mọi nền tảng).
//   2. Ảnh đường dẫn tệp máy tính/điện thoại (File Image): Đọc tệp trên Android/iOS/Desktop.
//   3. Ảnh Asset nội bộ ('assets/...'): Nạp tài nguyên đóng gói sẵn trong app.
//   4. Ảnh Web mạng ('https://...'): Tải và lưu đệm tự động qua CachedNetworkImage.
//   5. Ảnh Blob ('blob:...'): Xử lý URL tạm trên nền tảng Web.
//   6. Trường hợp rỗng hoặc lỗi: Tự động hiển thị chữ cái đầu tiên (Initials) hoặc Icon người mặc định.
// ============================================================================

import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';

class PlayerAvatar extends StatelessWidget {
  /// Đường dẫn hình ảnh (URL Web, Base64 Data URI, đường dẫn tệp máy hoặc asset)
  final String imageUrl;

  /// Bán kính của ảnh đại diện (Đường kính = radius * 2, mặc định là 28)
  final double radius;

  /// Ký tự viết tắt hiển thị khi chưa có ảnh (Ví dụ: 'S' cho Salah, 'V' cho Van Dijk)
  final String? initials;

  /// Màu sắc đường viền bao quanh ảnh (Tùy chọn)
  final Color? borderColor;

  /// Độ dày đường viền (Mặc định: 0)
  final double borderWidth;

  const PlayerAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 28,
    this.initials,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final trimmed = imageUrl.trim();

    // ------------------------------------------------------------------------
    // KHUNG THAY THẾ MẶC ĐỊNH (PLACEHOLDER)
    // Hiển thị khi ảnh bị lỗi, đang nạp hoặc đường dẫn bị trống
    // ------------------------------------------------------------------------
    Widget placeholder = Container(
      width: size,
      height: size,
      color: AppTheme.surfaceNavyLight,
      child: Center(
        child: initials != null && initials!.isNotEmpty
            ? Text(
                initials!,
                style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentCyan,
                ),
              )
            : Icon(
                Icons.person,
                size: radius,
                color: AppTheme.textSecondary,
              ),
      ),
    );

    Widget imageWidget;

    // ------------------------------------------------------------------------
    // PHÂN LOẠI VÀ XỬ LÝ NGUỒN ẢNH
    // ------------------------------------------------------------------------
    if (trimmed.isEmpty) {
      // Trường hợp 1: Không có đường dẫn ảnh -> Dùng khung thay thế
      imageWidget = placeholder;
    } else if (trimmed.startsWith('data:image') || trimmed.contains(';base64,')) {
      // Trường hợp 2: Ảnh tải từ thiết bị được mã hóa dạng Base64 Data URI
      // Ưu điểm: Không phụ thuộc internet, lưu trữ vĩnh viễn trong SharedPreferences
      try {
        final base64Str = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } catch (_) {
        imageWidget = placeholder;
      }
    } else if (trimmed.startsWith('blob:')) {
      // Trường hợp 3: Blob URL tạm thời từ trình duyệt Web
      imageWidget = Image.network(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (trimmed.startsWith('assets/')) {
      // Trường hợp 4: Ảnh tài nguyên nội bộ đóng gói trong thư mục assets
      imageWidget = Image.asset(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (!kIsWeb && (trimmed.startsWith('/') || trimmed.contains(':\\') || trimmed.contains(':/'))) {
      // Trường hợp 5: Đường dẫn tệp cục bộ trên ổ cứng Mobile/Desktop
      // Chú ý: Kiểm tra !kIsWeb để tránh lỗi Unsupported operation trên trình duyệt Web
      try {
        final file = io.File(trimmed);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => placeholder,
          );
        } else {
          imageWidget = placeholder;
        }
      } catch (_) {
        imageWidget = placeholder;
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      // Trường hợp 6: Đường dẫn URL trực tuyến từ Internet
      // Sử dụng CachedNetworkImage để lưu đệm vào bộ nhớ tạm tránh tải lại nhiều lần
      imageWidget = CachedNetworkImage(
        imageUrl: trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: AppTheme.surfaceNavyLight,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => placeholder,
      );
    } else {
      // Trường hợp ngoại lệ khác không xác định
      imageWidget = placeholder;
    }

    // ------------------------------------------------------------------------
    // CẮT ẢNH THEO KHUNG TRÒN VÀ TẠO VIỀN BẢO VỆ
    // ------------------------------------------------------------------------
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: imageWidget,
      ),
    );
  }
}
