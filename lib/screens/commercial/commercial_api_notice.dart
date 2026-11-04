import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CommercialApiNotice extends StatelessWidget {
  final String? error;
  final bool isLoading;
  final Future<void> Function() onRetry;

  const CommercialApiNotice({
    super.key,
    required this.error,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null && !isLoading) return const SizedBox.shrink();
    return Column(
      children: [
        if (error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_outlined, color: AppTheme.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không thể đồng bộ API. '
                    'Đang hiển thị dữ liệu đã lưu nếu có.\n$error',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onRetry(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        if (isLoading) const LinearProgressIndicator(minHeight: 2),
      ],
    );
  }
}
