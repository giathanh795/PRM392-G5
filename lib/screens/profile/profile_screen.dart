import '../auth/login_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, UserProfile current) {
    final nameCtrl = TextEditingController(text: current.fullName);
    final emailCtrl = TextEditingController(text: current.email);
    final phoneCtrl = TextEditingController(text: current.phone);
    final roleCtrl = TextEditingController(text: current.role);
    final deptCtrl = TextEditingController(text: current.department);
    final bioCtrl = TextEditingController(text: current.bio);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Row(
          children: [
            const Icon(Icons.manage_accounts, color: AppTheme.lfcRed, size: 24),
            const SizedBox(width: 8),
            Text(
              'Chỉnh sửa Hồ sơ Quản lý',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email công vụ'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Chức danh / Vai trò'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(labelText: 'Phòng ban / Bộ phận'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Tiểu sử & Trách nhiệm'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Hủy', style: TextStyle(color: AppTheme.subtextColor(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lfcRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final updated = current.copyWith(
                fullName: nameCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                role: roleCtrl.text.trim(),
                department: deptCtrl.text.trim(),
                bio: bioCtrl.text.trim(),
              );
              Navigator.of(dialogCtx).pop();
              await context.read<AppStateProvider>().updateUserProfile(updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật hồ sơ cá nhân lên SQL Database!')),
                );
              }
            },
            child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: AppTheme.lfcYellow, size: 24),
            const SizedBox(width: 8),
            Text(
              'Đổi mật khẩu tài khoản',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Hủy', style: TextStyle(color: AppTheme.subtextColor(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lfcYellow,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu xác nhận không khớp!')),
                );
                return;
              }
              final success = await context.read<AppStateProvider>().changePassword(
                    oldPassCtrl.text,
                    newPassCtrl.text,
                  );
              if (context.mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã đổi mật khẩu thành công trong SQL Database!'
                          : 'Mật khẩu hiện tại không chính xác!',
                    ),
                    backgroundColor: success ? AppTheme.success : AppTheme.danger,
                  ),
                );
              }
            },
            child: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangeAvatarDialog(BuildContext context, UserProfile current) {
    final picker = ImagePicker();
    final presetAvatars = [
      {'name': 'Arne Slot (Head Coach)', 'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80'},
      {'name': 'Sporting Director', 'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80'},
      {'name': 'Technical Director', 'url': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400&q=80'},
      {'name': 'Commercial Lead', 'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80'},
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        title: Row(
          children: [
            const Icon(Icons.add_a_photo_outlined, color: AppTheme.accentCyan, size: 22),
            const SizedBox(width: 8),
            Text(
              'Đổi ảnh đại diện Quản lý',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.photo_library),
                label: const Text('Tải ảnh từ máy tính (Tự động Base64)'),
                onPressed: () async {
                  try {
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 600,
                      maxHeight: 600,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                      final updated = current.copyWith(avatarUrl: base64Image);
                      if (!context.mounted) return;
                      Navigator.of(dialogCtx).pop();
                      await context.read<AppStateProvider>().updateUserProfile(updated);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật ảnh đại diện Base64!')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi tải ảnh: $e')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'HOẶC CHỌN ẢNH CHÂN DUNG CÓ SẴN:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.subtextColor(context)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: presetAvatars.map((item) {
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final updated = current.copyWith(avatarUrl: item['url']!);
                    Navigator.of(dialogCtx).pop();
                    await context.read<AppStateProvider>().updateUserProfile(updated);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã chọn ảnh ${item['name']}!')),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLightColor(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    child: Column(
                      children: [
                        PlayerAvatar(imageUrl: item['url']!, radius: 24),
                        const SizedBox(height: 4),
                        Text(
                          item['name']!.split(' ').first,
                          style: TextStyle(fontSize: 10, color: AppTheme.textColor(context)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Đóng', style: TextStyle(color: AppTheme.subtextColor(context))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final profile = state.userProfile;

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        title: const Text('Quản lý Hồ sơ Cá nhân'),
        actions: [

          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: state.isDarkMode ? AppTheme.lfcYellow : AppTheme.lfcRed,
            ),
            tooltip: state.isDarkMode ? 'Chuyển sang Chế độ Sáng' : 'Chuyển sang Chế độ Tối',
            onPressed: () => state.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Card(
                  color: AppTheme.cardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            PlayerAvatar(
                              imageUrl: profile.avatarUrl,
                              radius: 48,
                              initials: profile.fullName.isNotEmpty ? profile.fullName[0] : 'A',
                              borderColor: AppTheme.lfcRed,
                              borderWidth: 2.5,
                            ),
                            InkWell(
                              onTap: () => _showChangeAvatarDialog(context, profile),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.lfcRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 6, children: [Text(profile.fullName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: AppTheme.success),
                                  SizedBox(width: 4),
                                  Text(
                                    'ĐÃ ĐĂNG NHẬP',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.role,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lfcRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.department,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.subtextColor(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.lfcRed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => _showEditProfileDialog(context, profile),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textColor(context),
                                side: BorderSide(color: AppTheme.borderColor(context)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.lock_outline, size: 16),
                              label: const Text('Đổi mật khẩu'),
                              onPressed: () => _showChangePasswordDialog(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  color: AppTheme.cardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, color: AppTheme.accentCyan, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Chi tiết Tài khoản & Liên hệ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor(context),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(context, Icons.account_circle_outlined, 'Tên đăng nhập', profile.username),
                        _buildDetailRow(context, Icons.email_outlined, 'Email công vụ', profile.email),
                        _buildDetailRow(context, Icons.phone_outlined, 'Số điện thoại', profile.phone),
                        _buildDetailRow(context, Icons.business_outlined, 'Bộ phận', profile.department),
                        _buildDetailRow(context, Icons.info_outline, 'Tiểu sử', profile.bio),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  color: AppTheme.cardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storage_rounded, color: AppTheme.lfcYellow, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cơ sở dữ liệu SQL & Backend',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'SQL ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hệ thống đang chạy với Spring Boot REST API & H2 Relational SQL Database.',
                          style: TextStyle(fontSize: 12, color: AppTheme.subtextColor(context)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSqlBadge(context, 'Table: users'),
                            _buildSqlBadge(context, 'Table: players'),
                            _buildSqlBadge(context, 'Table: sponsorships'),
                            _buildSqlBadge(context, 'Table: campaigns'),
                            _buildSqlBadge(context, 'Table: training_sessions'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLightColor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderColor(context)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.terminal, size: 18, color: AppTheme.accentCyan),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'H2 Web Console có sẵn tại: http://localhost:8080/h2-console',
                                  style: TextStyle(fontSize: 11, color: AppTheme.subtextColor(context)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  color: AppTheme.cardColor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      state.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: state.isDarkMode ? AppTheme.accentCyan : AppTheme.lfcRed,
                    ),
                    title: Text(
                      'Chế độ Giao diện (Theme Mode)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor(context),
                      ),
                    ),
                    subtitle: Text(
                      state.isDarkMode ? 'Đang bật Giao diện Tối (Liverpool Dark Navy)' : 'Đang bật Giao diện Sáng (Premier League White)',
                      style: TextStyle(fontSize: 12, color: AppTheme.subtextColor(context)),
                    ),
                    value: state.isDarkMode,
                    activeThumbColor: AppTheme.accentCyan,
                    onChanged: (_) => state.toggleTheme(),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  color: state.isDarkMode ? AppTheme.surfaceNavy : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.lfcRed, width: 1.2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lfcRed.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout, color: AppTheme.lfcRed, size: 20),
                    ),
                    title: const Text(
                      'Đăng Xuất Tài Khoản',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lfcRed,
                      ),
                    ),
                    subtitle: Text(
                      'Thoát phiên làm việc và quay về màn hình Đăng nhập',
                      style: TextStyle(fontSize: 12, color: AppTheme.subtextColor(context)),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.lfcRed),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.cardColor(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppTheme.borderColor(context)),
                          ),
                          title: const Text('Xác nhận Đăng xuất'),
                          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi cổng điều hành Liverpool FC?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.lfcRed),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Đăng Xuất', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await context.read<AppStateProvider>().logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.subtextColor(context)),
          const SizedBox(width: 12),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.subtextColor(context)),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Chưa cập nhật',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSqlBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLightColor(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600),
      ),
    );
  }
}
