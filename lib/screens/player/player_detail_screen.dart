import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_avatar.dart';
import 'player_stats_screen.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  // Mở trình phát / Xem URL (Hỗ trợ Youtube, trang Web, file video MP4, v.v.)
  Future<void> _launchMediaUrl(BuildContext context, PlayerMediaItem item) async {
    final rawUrl = item.url.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đường dẫn media trống!')),
      );
      return;
    }

    final formattedUrl = (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))
        ? rawUrl
        : 'https://$rawUrl';

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

  // Hộp thoại Thêm Video / Ảnh PR mới
  void _showAddMediaDialog(BuildContext context, Player currentPlayer) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String mediaType = 'video';

    final presetVideos = [
      {'title': 'Adidas Football Official Spot', 'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'},
      {'title': 'Liverpool FC Training Highlights', 'url': 'https://www.youtube.com/c/LiverpoolFC'},
      {'title': 'Florian Wirtz Skills & Goals', 'url': 'https://www.youtube.com/results?search_query=florian+wirtz'},
      {'title': 'Alexander Isak Top Finishes', 'url': 'https://www.youtube.com/results?search_query=alexander+isak'},
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
                      onSelected: (_) => setDialogState(() => mediaType = 'video'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Ảnh chụp (Photo)'),
                      selected: mediaType == 'photo',
                      selectedColor: AppTheme.accentBlue,
                      onSelected: (_) => setDialogState(() => mediaType = 'photo'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề chiến dịch / Video',
                    hintText: 'Ví dụ: Adidas Predator 2026 Promo...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Đường dẫn (URL Video hoặc Ảnh)',
                    hintText: 'https://youtube.com/... hoặc link mp4/ảnh',
                    prefixIcon: Icon(
                      mediaType == 'video' ? Icons.play_circle_fill : Icons.photo,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Hoặc chọn nhanh link video mẫu:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presetVideos.map((v) {
                    return ActionChip(
                      label: Text(v['title']!, style: const TextStyle(fontSize: 10)),
                      backgroundColor: AppTheme.surfaceNavyLight,
                      onPressed: () {
                        setDialogState(() {
                          titleController.text = v['title']!;
                          urlController.text = v['url']!;
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
                    const SnackBar(content: Text('Vui lòng điền tiêu đề và đường link tư liệu!')),
                  );
                }
              },
              child: const Text('Thêm ngay'),
            ),
          ],
        ),
      ),
    );
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
            tooltip: 'View Stats & Progress',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerStatsScreen(player: currentPlayer),
                ),
              );
            },
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

            // Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.radar),
                    label: const Text('Radar & Chỉ Số'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerStatsScreen(player: currentPlayer),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.monetization_on, color: AppTheme.lfcYellow),
                    label: Text('€${currentPlayer.currentMarketValue.toStringAsFixed(0)}M Value'),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bio & Contract Information
            const Text(
              'Profile & Contract Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
