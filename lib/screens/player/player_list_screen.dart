import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/player.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/player_card_item.dart';
import '../../widgets/delete_player_dialog.dart';
import '../../widgets/player_form_dialog.dart';
import 'player_detail_screen.dart';

/// ============================================================================
/// MÀN HÌNH DANH SÁCH CẦU THỦ (PLAYER LIST SCREEN)
/// ============================================================================
/// Mục đích:
/// - Hiển thị toàn bộ danh sách đội hình Liverpool FC.
/// - Tìm kiếm theo tên, số áo, quốc tịch bằng TextField thời gian thực.
/// - Lọc theo các tuyến vị trí thi đấu (All, Tiền đạo, Tiền vệ, Hậu vệ, Thủ môn).
/// - Khởi tạo luồng Thêm mới cầu thủ qua nút Add (+) trên AppBar.
/// - Hỗ trợ thao tác Xóa cầu thủ (qua nút bấm hoặc vuốt thẻ sang trái) kèm
///   hộp thoại xác nhận an toàn và chức năng HOÀN TÁC (Undo) trong 4 giây.
/// - Chuyển sang màn hình Chi tiết cầu thủ khi nhấn vào thẻ.
/// ============================================================================

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  /// ==========================================================================
  /// LUỒNG XỬ LÝ XÓA CẦU THỦ VÀ HOÀN TÁC (DELETE & UNDO FLOW):
  /// 1. Hiển thị hộp thoại cảnh báo showDeletePlayerConfirmationDialog.
  /// 2. Nếu người dùng chọn "Xóa":
  ///    - Ghi nhận vị trí (index) gốc của cầu thủ trong danh sách.
  ///    - Gọi AppStateProvider.deletePlayer() để xóa khỏi RAM và lưu SharedPreferences.
  ///    - Hiển thị SnackBar nổi thông báo xóa thành công với nút "HOÀN TÁC".
  /// 3. Nếu bấm "HOÀN TÁC" trước khi SnackBar đóng (4s):
  ///    - Gọi AppStateProvider.restorePlayer() để khôi phục lại cầu thủ về đúng vị trí cũ.
  /// ==========================================================================
  Future<void> _handleDeletePlayer(BuildContext context, Player player) async {
    // Bước 1: Hiển thị Dialog xác nhận
    final confirmed = await showDeletePlayerConfirmationDialog(context, player);

    // Bước 2: Thực hiện xóa nếu người dùng đã xác nhận
    if (confirmed == true && context.mounted) {
      final originalIndex = context.read<AppStateProvider>().players.indexWhere((p) => p.id == player.id);
      final deleted = await context.read<AppStateProvider>().deletePlayer(player.id);

      // Bước 3: Hiển thị SnackBar thông báo kèm nút "HOÀN TÁC"
      if (context.mounted && deleted != null) {
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
                    'Đã xóa cầu thủ "${player.name}"',
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
                // Khôi phục lại cầu thủ vào đúng index cũ
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

  /// ==========================================================================
  /// LUỒNG KHÔI PHỤC DANH SÁCH GỐC (RESET TO DEFAULT ROSTER):
  /// - Dùng khi người dùng xóa hết cầu thủ hoặc muốn nạp lại 25 cầu thủ gốc chuẩn LFC.
  /// - Xóa dữ liệu tùy chỉnh trong SharedPreferences và tải lại MockData.
  /// ==========================================================================
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: AppTheme.lfcYellow, size: 24),
            SizedBox(width: 8),
            Text('Khôi phục danh sách', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn có muốn đặt lại toàn bộ danh sách 25 cầu thủ Liverpool FC về trạng thái mặc định ban đầu không?',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lfcYellow,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await context.read<AppStateProvider>().resetToDefaultMockData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã khôi phục toàn bộ danh sách 25 cầu thủ Liverpool FC!'),
                  ),
                );
              }
            },
            child: const Text('Khôi phục ngay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi danh sách cầu thủ, bộ lọc vị trí và từ khóa tìm kiếm
    final state = context.watch<AppStateProvider>();
    final positions = ['All', 'Forward', 'Midfielder', 'Defender', 'Goalkeeper'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liverpool Squad'),
        actions: [
          // Nút mở Dialog Thêm mới cầu thủ (Create)
          IconButton(
            icon: Icon(
              state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: state.isDarkMode ? AppTheme.accentGold : Colors.amber.shade700,
            ),
            tooltip: state.isDarkMode
                ? 'Chuyển sang Giao diện Sáng'
                : 'Chuyển sang Giao diện Tối',
            onPressed: () => context.read<AppStateProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Thêm cầu thủ mới',
            onPressed: () => showPlayerFormDialog(context),
          ),
          // Menu chức năng phụ: Khôi phục danh sách mặc định
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppTheme.surfaceNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            onSelected: (val) {
              if (val == 'reset') {
                _showResetConfirmation(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt, size: 18, color: AppTheme.lfcYellow),
                    SizedBox(width: 8),
                    Text(
                      'Khôi phục 25 cầu thủ gốc',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ------------------------------------------------------------------
          // 1. THANH TÌM KIẾM CẦU THỦ (Tên, Số áo, Quốc tịch)
          // ------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search player by name, number, nationality...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                        onPressed: () => context.read<AppStateProvider>().setSearchQuery(''),
                      )
                    : null,
              ),
              onChanged: (val) => context.read<AppStateProvider>().setSearchQuery(val),
            ),
          ),

          // ------------------------------------------------------------------
          // 2. THANH CUỘN BỘ LỌC VỊ THI ĐẤU (Position Filter Chips)
          // ------------------------------------------------------------------
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: positions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final pos = positions[index];
                final isSelected = state.selectedPositionFilter.toLowerCase() == pos.toLowerCase();

                return ChoiceChip(
                  label: Text(pos),
                  selected: isSelected,
                  selectedColor: AppTheme.lfcRed,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (_) => context.read<AppStateProvider>().setPositionFilter(pos),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ------------------------------------------------------------------
          // 3. THÔNG BÁO SỐ LƯỢNG CẦU THỦ KHỚP BỘ LỌC
          // ------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${state.filteredPlayers.length} players',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const Row(
                  children: [
                    Icon(Icons.shield, size: 14, color: AppTheme.lfcRed),
                    SizedBox(width: 4),
                    Text('LFC Official Roster', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // ------------------------------------------------------------------
          // 4. DANH SÁCH CẦU THỦ HOẶC MÀN HÌNH BÁO TRỐNG
          // ------------------------------------------------------------------
          Expanded(
            child: state.filteredPlayers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            state.players.isEmpty ? Icons.group_off_outlined : Icons.search_off,
                            size: 56,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.players.isEmpty
                                ? 'Danh sách đội hình hiện đang trống.'
                                : 'Không tìm thấy cầu thủ nào phù hợp.',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                          // Nút khôi phục nhanh nếu toàn bộ danh sách đã bị xóa
                          if (state.players.isEmpty) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.lfcRed,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.restart_alt, size: 18),
                              label: const Text('Khôi phục 25 cầu thủ gốc'),
                              onPressed: () => context.read<AppStateProvider>().resetToDefaultMockData(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = state.filteredPlayers[index];

                      // Widget Dismissible cho phép thao tác vuốt sang trái để Xóa
                      return Dismissible(
                        key: ValueKey('player_${player.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.lfcRed.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Xóa cầu thủ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Xác nhận trước khi kích hoạt vuốt xóa
                        confirmDismiss: (direction) async {
                          return await showDeletePlayerConfirmationDialog(context, player);
                        },
                        // Xóa cầu thủ khi hoàn thành thao tác vuốt
                        onDismissed: (direction) async {
                          final originalIndex = context.read<AppStateProvider>().players.indexWhere((p) => p.id == player.id);
                          final deleted = await context.read<AppStateProvider>().deletePlayer(player.id);
                          if (context.mounted && deleted != null) {
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
                                        'Đã xóa cầu thủ "${player.name}"',
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
                        },
                        // Thẻ cầu thủ chính
                        child: PlayerCardItem(
                          player: player,
                          onTap: () {
                            // Chọn cầu thủ và chuyển đến màn hình chi tiết
                            context.read<AppStateProvider>().selectPlayer(player);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerDetailScreen(player: player),
                              ),
                            );
                          },
                          // Nút sửa thông tin cầu thủ
                          onEdit: () => showPlayerFormDialog(context, player: player),
                          // Nút xóa cầu thủ
                          onDelete: () => _handleDeletePlayer(context, player),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
