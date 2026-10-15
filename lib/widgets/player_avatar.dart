import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';

class PlayerAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String? initials;
  final Color? borderColor;
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
    if (trimmed.isEmpty) {
      imageWidget = placeholder;
    } else if (trimmed.startsWith('data:image') || trimmed.contains(';base64,')) {
      // Base64 Data URI (Hỗ trợ 100% Web, Mobile, Desktop, lưu trữ vĩnh viễn)
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
      // Blob URL từ trình duyệt Web
      imageWidget = Image.network(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (trimmed.startsWith('assets/')) {
      // Local App Asset
      imageWidget = Image.asset(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (!kIsWeb && (trimmed.startsWith('/') || trimmed.contains(':\\') || trimmed.contains(':/'))) {
      // Local File Image trên Mobile / Desktop (Tuyệt đối không gọi trên Web để tránh lỗi Unsupported operation: _Namespace)
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
      // Network URL Image (Cached)
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
      imageWidget = placeholder;
    }

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
