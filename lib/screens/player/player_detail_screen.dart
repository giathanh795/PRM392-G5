import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/delete_player_dialog.dart';
import '../../widgets/player_form_dialog.dart';
import 'player_stats_screen.dart';

/// ============================================================================
/// MÀN HÌNH CHI TIẾT CẦU THỦ (PLAYER DETAIL SCREEN)
/// ============================================================================
/// Mục đích:
/// - Hiển thị hồ sơ toàn diện của một cầu thủ Liverpool FC.
/// - Đồng bộ dữ liệu theo thời gian thực (Reactive) qua AppStateProvider.
/// - Cho phép Chỉnh sửa toàn bộ thông tin (nút Edit trên AppBar).
/// - Quản lý tư liệu PR & Video (tải video/ảnh trực tiếp từ thiết bị, xem/phát).
/// - Thay đổi ảnh đại diện (chọn từ máy hoặc preset).
/// - Hiển thị biểu đồ năng lực kỹ thuật (Radar chart / Bar chart).
/// - Xem lịch sử biến động giá trị chuyển nhượng trên thị trường.
/// - Vùng xóa cầu thủ (Danger Zone) kèm cảnh báo và chức năng HOÀN TÁC.
/// ============================================================================
class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  // Mở trình phát / Xem URL (Hỗ trợ Youtube, trang Web, file video MP4, ảnh Base64, v.v.)
  Future<void> _launchMediaUrl(BuildContext context, PlayerMediaItem item) async {
    final rawUrl = item.url.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đường dẫn media trống!')),
      );
      return;
    }

    // Nếu là ảnh tải lên từ thiết bị dạng base64
    if (rawUrl.startsWith('data:image')) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppTheme.surfaceNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.memory(
                  base64Decode(rawUrl.split(',').last),
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final formattedUrl = (rawUrl.startsWith('http://') || rawUrl.startsWith('https://') || rawUrl.startsWith('file://'))
        ? rawUrl
        : (rawUrl.contains(':\\') || rawUrl.startsWith('/') ? 'file://$rawUrl' : 'https://$rawUrl');

    final uri = Uri.tryParse(formattedUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đường dẫn không hợp lệ: $formattedUrl')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );

      if (!launched && context.mounted) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở liên kết: $e')),
        );
      }
    }
  }

  // Hộp thoại chỉnh sửa Avatar (Cho phép dán URL, chọn từ Thư viện máy, hoặc chọn Preset)
  void _showEditAvatarDialog(BuildContext context, Player currentPlayer) {
    final controller = TextEditingController(text: currentPlayer.avatarUrl);
    final picker = ImagePicker();

    final presetImages = [
      {'name': 'Chân dung 1', 'url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80'},
      {'name': 'Chân dung 2', 'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&q=80'},
      {'name': 'Chân dung 3', 'url': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=400&q=80'},
      {'name': 'Chân dung 4', 'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80'},
      {'name': 'Chân dung 5', 'url': 'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=400&q=80'},
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, color: AppTheme.accentCyan, size: 22),
              SizedBox(width: 8),
              Text('Đổi ảnh đại diện (Avatar)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nút chọn ảnh trực tiếp từ bộ sưu tập máy tính / điện thoại
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentCyan,
                      side: const BorderSide(color: AppTheme.accentCyan),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh từ Thư viện / Thiết bị'),
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
                          setDialogState(() {
                            controller.text = base64Image;
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Không thể mở thư viện: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.borderSubtle)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('HOẶC DÁN LINK URL', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ),
                    Expanded(child: Divider(color: AppTheme.borderSubtle)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'https://... hoặc đường dẫn file',
                    labelText: 'Đường dẫn ảnh',
                    prefixIcon: const Icon(Icons.link, color: AppTheme.accentCyan),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setDialogState(() {
                                controller.clear();
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 14),

                // Xem trước ảnh (Live Preview)
                Center(
                  child: Column(
                    children: [
                      const Text('Xem trước ảnh:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      const SizedBox(height: 6),
                      PlayerAvatar(
                        imageUrl: controller.text,
                        radius: 36,
                        initials: currentPlayer.name.isNotEmpty ? currentPlayer.name[0] : '?',
                        borderColor: AppTheme.accentCyan,
                        borderWidth: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Hoặc chọn nhanh ảnh mẫu Liverpool:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presetImages.map((preset) {
                    return ActionChip(
                      label: Text(preset['name']!, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppTheme.surfaceNavyLight,
                      onPressed: () {
                        setDialogState(() {
                          controller.text = preset['url']!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newUrl = controller.text.trim();
                final updated = currentPlayer.copyWith(avatarUrl: newUrl);
                await context.read<AppStateProvider>().updatePlayer(updated);
                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật và lưu ảnh đại diện cho ${currentPlayer.name}!')),
                  );
                }
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  // Hộp thoại Thêm Video / Ảnh PR mới từ máy tính hoặc link
  /// ==========================================================================
  /// LUỒNG THÊM TƯ LIỆU PR / VIDEO TỪ MÁY HOẶC ĐƯỜNG DẪN:
  /// 1. Cho phép người dùng chọn phân loại: "Video PR" hoặc "Ảnh chụp (Photo)".
  /// 2. Hỗ trợ nút "Tải file từ máy lên":
  ///    - Nếu là Video: picker.pickVideo(source: ImageSource.gallery) lấy đường dẫn file.
  ///    - Nếu là Ảnh: picker.pickImage(...) đọc bytes và mã hóa Base64 Data URI.
  /// 3. Tự động trích xuất tên file làm tiêu đề mặc định.
  /// 4. Khi nhấn "Thêm ngay": Khởi tạo đối tượng PlayerMediaItem, chèn vào mediaList,
  ///    và gọi AppStateProvider.updatePlayer() để lưu trữ bền vững.
  /// ==========================================================================
  void _showAddMediaDialog(BuildContext context, Player currentPlayer) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String mediaType = 'video';
    String? uploadedFileName;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickMediaFile() async {
            try {
              if (mediaType == 'video') {
                final picked = await picker.pickVideo(source: ImageSource.gallery);
                if (picked != null) {
                  setDialogState(() {
                    uploadedFileName = picked.name;
                    urlController.text = picked.path;
                    if (titleController.text.trim().isEmpty) {
                      titleController.text = picked.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
                    }
                  });
                }
              } else {
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1200,
                  maxHeight: 1200,
                  imageQuality: 85,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                  setDialogState(() {
                    uploadedFileName = picked.name;
                    urlController.text = base64Image;
                    if (titleController.text.trim().isEmpty) {
                      titleController.text = picked.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
                    }
                  });
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Không thể chọn tệp: $e')),
                );
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppTheme.surfaceNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            title: const Row(
              children: [
                Icon(Icons.video_library_outlined, color: AppTheme.lfcRed, size: 22),
                SizedBox(width: 8),
                Text('Thêm tư liệu PR / Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loại tư liệu PR:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Video PR'),
                        selected: mediaType == 'video',
                        selectedColor: AppTheme.lfcRed,
                        onSelected: (_) => setDialogState(() {
                          mediaType = 'video';
                          uploadedFileName = null;
                          urlController.clear();
                        }),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Ảnh chụp (Photo)'),
                        selected: mediaType == 'photo',
                        selectedColor: AppTheme.accentBlue,
                        onSelected: (_) => setDialogState(() {
                          mediaType = 'photo';
                          uploadedFileName = null;
                          urlController.clear();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Khu vực tải file trực tiếp từ máy tính / điện thoại
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceNavyLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: uploadedFileName != null
                            ? AppTheme.accentCyan
                            : AppTheme.borderSubtle,
                        width: uploadedFileName != null ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          uploadedFileName != null
                              ? Icons.check_circle_outline_rounded
                              : (mediaType == 'video' ? Icons.video_file_outlined : Icons.add_photo_alternate_outlined),
                          size: 40,
                          color: uploadedFileName != null
                              ? AppTheme.accentCyan
                              : (mediaType == 'video' ? AppTheme.lfcRed : AppTheme.accentCyan),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          uploadedFileName != null
                              ? 'Đã tải lên: $uploadedFileName'
                              : (mediaType == 'video' ? 'Chọn file Video từ máy tính / thiết bị' : 'Chọn file Ảnh từ máy tính / thiết bị'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: uploadedFileName != null ? FontWeight.bold : FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mediaType == 'video'
                              ? 'Định dạng: MP4, MOV, MKV, AVI...'
                              : 'Định dạng: JPG, PNG, WEBP...',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mediaType == 'video' ? AppTheme.lfcRed : AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: Text(uploadedFileName != null ? 'Chọn tệp khác' : 'Tải file từ máy lên'),
                          onPressed: pickMediaFile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề tư liệu / Video *',
                      hintText: 'Ví dụ: Highlights tập luyện, Phỏng vấn...',
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'Đường dẫn tệp / URL',
                      hintText: uploadedFileName != null ? 'Đã liên kết tệp từ máy' : 'https://youtube.com/... hoặc link web',
                      prefixIcon: Icon(
                        uploadedFileName != null ? Icons.folder_open : (mediaType == 'video' ? Icons.play_circle_fill : Icons.photo),
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lfcRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  final url = urlController.text.trim();
                  if (title.isNotEmpty && url.isNotEmpty) {
                    final newItem = PlayerMediaItem(
                      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      type: mediaType,
                      url: url,
                      date: '2026-10-12',
                    );
                    final updatedList = List<PlayerMediaItem>.from(currentPlayer.mediaList)..add(newItem);
                    final updated = currentPlayer.copyWith(mediaList: updatedList);
                    context.read<AppStateProvider>().updatePlayer(updated);
                    Navigator.of(dialogCtx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã thêm tư liệu PR mới: $title')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn tệp từ máy hoặc điền đầy đủ tiêu đề và đường dẫn!')),
                    );
                  }
                },
                child: const Text('Thêm ngay'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ==========================================================================
  /// LUỒNG XÓA CẦU THỦ TẠI MÀN HÌNH CHI TIẾT:
  /// 1. Hiển thị Dialog cảnh báo showDeletePlayerConfirmationDialog.
  /// 2. Nếu người dùng xác nhận xóa:
  ///    - Gọi AppStateProvider.deletePlayer(id).
  ///    - Navigator.of(context).pop() để đóng màn hình chi tiết và quay về danh sách.
  ///    - Hiển thị SnackBar nổi thông báo xóa kèm nút "HOÀN TÁC" (4 giây).
  /// ==========================================================================
  Future<void> _handleDeletePlayer(BuildContext context, Player currentPlayer) async {
    final confirmed = await showDeletePlayerConfirmationDialog(context, currentPlayer);
    if (confirmed == true && context.mounted) {
      final originalIndex = context.read<AppStateProvider>().players.indexWhere((p) => p.id == currentPlayer.id);
      final deleted = await context.read<AppStateProvider>().deletePlayer(currentPlayer.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        if (deleted != null) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.surfaceNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.accentCyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã xóa cầu thủ "${currentPlayer.name}"',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'HOÀN TÁC',
                textColor: AppTheme.lfcYellow,
                onPressed: () {
                  context.read<AppStateProvider>().restorePlayer(
                    originalIndex >= 0 ? originalIndex : 0,
                    deleted,
                  );
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final currentPlayer = state.players.firstWhere(
      (p) => p.id == player.id,
      orElse: () => player,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlayer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Xem chỉ số & Tiến độ',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerStatsScreen(player: currentPlayer),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.accentCyan),
            tooltip: 'Chỉnh sửa cầu thủ',
            onPressed: () => showPlayerFormDialog(context, player: currentPlayer),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.lfcRed),
            tooltip: 'Xóa cầu thủ',
            onPressed: () => _handleDeletePlayer(context, currentPlayer),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Player Card Header với PlayerAvatar & Nút Edit Avatar
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.surfaceNavyLight, AppTheme.surfaceNavy],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        PlayerAvatar(
                          imageUrl: currentPlayer.avatarUrl,
                          radius: 46,
                          initials: currentPlayer.name.isNotEmpty ? currentPlayer.name[0] : '?',
                          borderColor: AppTheme.accentCyan,
                          borderWidth: 2,
                        ),
                        InkWell(
                          onTap: () => _showEditAvatarDialog(context, currentPlayer),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '#${currentPlayer.number} ${currentPlayer.name}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentPlayer.positionName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentPlayer.nationality,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.adidasBlack,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Text(
                            'adidas',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nổi bật: PHÂN TÍCH CHUYÊN MÔN & BIỂU ĐỒ RADAR (OWNER ANALYTICS CARD)
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerStatsScreen(player: currentPlayer),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.isDark(context)
                        ? [
                            const Color(0xFF1E3A5F),
                            const Color(0xFF0F2744),
                          ]
                        : [
                            const Color(0xFFEFF6FF),
                            Colors.white,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.accentCyan.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentCyan, width: 1.5),
                      ),
                      child: const Icon(Icons.radar, color: AppTheme.accentCyan, size: 26),
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
                                  'Phân Tích Chuyên Môn & Radar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textColor(context),
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'RADAR 6-AXIS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentCyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Xem biểu đồ đa giác cho ${currentPlayer.positionName} & nút bật/tắt tiến độ kỹ thuật',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.subtextColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 13, color: AppTheme.accentCyan),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Bio & Contract Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile & Contract Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => showPlayerFormDialog(context, player: currentPlayer),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Date of Birth', currentPlayer.dateOfBirth),
                    const Divider(color: AppTheme.borderSubtle, height: 20),
                    _buildInfoRow('Height / Weight', '${currentPlayer.height} / ${currentPlayer.weight}'),
                    const Divider(color: AppTheme.borderSubtle, height: 20),
                    _buildInfoRow('Preferred Foot', currentPlayer.preferredFoot),
                    const Divider(color: AppTheme.borderSubtle, height: 20),
                    _buildInfoRow('Contract Until', currentPlayer.contractUntil),
                    const Divider(color: AppTheme.borderSubtle, height: 20),
                    _buildInfoRow('Squad Status', currentPlayer.status),
                    const Divider(color: AppTheme.borderSubtle, height: 20),
                    _buildInfoRow('Commercial Sponsor', currentPlayer.sponsorPartner),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Player PR & Media Section với Nút "+ Thêm Tư Liệu PR"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Media & PR Assets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceNavyLight,
                    foregroundColor: AppTheme.accentCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm PR/Video', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddMediaDialog(context, currentPlayer),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (currentPlayer.mediaList.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.perm_media_outlined, size: 36, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        const Text('Chưa có tư liệu PR hoặc video cho cầu thủ này.', style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16, color: AppTheme.accentCyan),
                          label: const Text('Thêm video PR ngay', style: TextStyle(color: AppTheme.accentCyan)),
                          onPressed: () => _showAddMediaDialog(context, currentPlayer),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentPlayer.mediaList.length,
                itemBuilder: (context, index) {
                  final item = currentPlayer.mediaList[index];
                  final isVideo = item.type == 'video';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceNavyLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isVideo ? Icons.play_circle_fill : Icons.photo_library,
                          color: isVideo ? AppTheme.lfcRed : AppTheme.accentCyan,
                          size: 26,
                        ),
                      ),
                      title: Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${item.type.toUpperCase()} • Nhấn để phát video',
                        style: TextStyle(
                          fontSize: 12,
                          color: isVideo ? AppTheme.accentCyan : AppTheme.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                            tooltip: 'Xóa tư liệu',
                            onPressed: () {
                              final updatedList = List<PlayerMediaItem>.from(currentPlayer.mediaList)..removeAt(index);
                              final updated = currentPlayer.copyWith(mediaList: updatedList);
                              context.read<AppStateProvider>().updatePlayer(updated);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã xóa tư liệu PR')),
                              );
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isVideo ? AppTheme.lfcRed.withValues(alpha: 0.15) : AppTheme.surfaceNavyLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isVideo ? Icons.play_arrow : Icons.open_in_new,
                              size: 18,
                              color: isVideo ? AppTheme.lfcRed : AppTheme.accentCyan,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _launchMediaUrl(context, item),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            // Khu vực quản lý / Xóa cầu thủ (Danger Zone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lfcRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.lfcRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lfcRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppTheme.lfcRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xóa cầu thủ này',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Xóa khỏi đội hình chính thức của LFC',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.lfcRed,
                      side: const BorderSide(color: AppTheme.lfcRed),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text(
                      'Xóa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _handleDeletePlayer(context, currentPlayer),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }
}
