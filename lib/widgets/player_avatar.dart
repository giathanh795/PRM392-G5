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
  final bool isInjured;

  const PlayerAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 28,
    this.initials,
    this.borderColor,
    this.borderWidth = 0,
    this.isInjured = false,
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

      imageWidget = Image.network(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (trimmed.startsWith('assets/')) {

      imageWidget = Image.asset(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (!kIsWeb && (trimmed.startsWith('/') || trimmed.contains(':\\') || trimmed.contains(':/'))) {

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

    final effectiveBorderColor = isInjured ? AppTheme.danger : borderColor;
    final effectiveBorderWidth = isInjured
        ? (borderWidth > 0 ? (borderWidth < 2.5 ? 2.5 : borderWidth) : 2.5)
        : borderWidth;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: effectiveBorderColor != null
                ? Border.all(color: effectiveBorderColor, width: effectiveBorderWidth)
                : null,
            boxShadow: isInjured
                ? [
                    BoxShadow(
                      color: AppTheme.danger.withValues(alpha: 0.65),
                      blurRadius: 9,
                      spreadRadius: 1.5,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: imageWidget,
          ),
        ),
        if (isInjured)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: AppTheme.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services,
                color: Colors.white,
                size: 9,
              ),
            ),
          ),
      ],
    );
  }
}
