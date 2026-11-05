import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/training_session.dart';
import '../models/sponsor_campaign.dart';
import '../data/mock_data.dart';

/// ============================================================================
/// APP STATE PROVIDER: QUẢN LÝ TRẠNG THÁI TOÀN CỤC CỦA ỨNG DỤNG (STATE MANAGEMENT)
/// ============================================================================
/// Lớp này kế thừa ChangeNotifier để lắng nghe và thông báo cho toàn bộ Widget
/// khi có sự thay đổi dữ liệu (Thêm, Sửa, Xóa, Tìm kiếm, Lọc cầu thủ).
/// Đồng thời chịu trách nhiệm lưu trữ và phục hồi dữ liệu từ SharedPreferences.
class AppStateProvider extends ChangeNotifier {
  // Khóa định danh dùng để lưu danh sách cầu thủ dạng JSON trong bộ nhớ máy
  static const String _playersStorageKey = 'lfc_players_data_v1';
  
  // Danh sách cầu thủ nội bộ trong bộ nhớ RAM
  List<Player> _players = List.from(MockData.players);
  final List<TrainingSession> _trainings = List.from(MockData.trainingSessions);
  final List<SponsorCampaign> _campaigns = List.from(MockData.sponsorCampaigns);
  
  // Trạng thái tìm kiếm và bộ lọc vị trí
  String _selectedPositionFilter = 'All';
  String _searchQuery = '';
  Player? _selectedPlayer;
  bool _isInitialized = false;

  /// KHỞI TẠO: Tự động gọi hàm nạp dữ liệu từ bộ nhớ SharedPreferences khi Provider được dựng
  AppStateProvider() {
    _loadPlayersFromStorage();
  }

  // --- GETTERS: Các hàm lấy dữ liệu ra ngoài cho UI tiêu thụ ---
  List<Player> get players => _players;
  List<TrainingSession> get trainings => _trainings;
  List<SponsorCampaign> get campaigns => _campaigns;
  String get selectedPositionFilter => _selectedPositionFilter;
  String get searchQuery => _searchQuery;
  Player? get selectedPlayer => _selectedPlayer ?? (_players.isNotEmpty ? _players.first : null);
  bool get isInitialized => _isInitialized;

  /// LUỒNG LỌC & TÌM KIẾM DỮ LIỆU THỜI GIAN THỰC (Real-time Filtering):
  /// - Lọc theo tuyến thi đấu (Forward, Midfielder, Defender, Goalkeeper hoặc All)
  /// - Tìm kiếm theo tên cầu thủ, quốc tịch hoặc số áo
  List<Player> get filteredPlayers {
    return _players.where((player) {
      final matchesPosition = _selectedPositionFilter == 'All' ||
          player.position.name.toLowerCase() == _selectedPositionFilter.toLowerCase();
      final matchesSearch = player.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          player.nationality.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          player.number.toString().contains(_searchQuery);
      return matchesPosition && matchesSearch;
    }).toList();
  }

  /// Tính tổng giá trị chuyển nhượng của cả đội hình
  double get totalMarketValue {
    return _players.fold(0.0, (sum, p) => sum + p.currentMarketValue);
  }

  /// LUỒNG 1: NẠP DỮ LIỆU TỪ BỘ NHỚ MÁY (SharedPreferences)
  /// - Kiểm tra khóa lưu trữ `_playersStorageKey`
  /// - Nếu có dữ liệu đã lưu: Giải mã JSON thành danh sách Player
  /// - Nếu chưa từng lưu (lần đầu mở app): Lấy dữ liệu mặc định từ MockData
  /// - Nạp lại avatar tùy chỉnh của từng cầu thủ
  /// - Báo cho UI dựng lại màn hình bằng notifyListeners()
  Future<void> _loadPlayersFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedJson = prefs.getString(_playersStorageKey);
      List<Player> loadedList = [];

      // 1. Phục hồi từ danh sách JSON đã lưu (nếu có)
      if (savedJson != null && savedJson.isNotEmpty) {
        try {
          final List<dynamic> decodedList = jsonDecode(savedJson);
          for (final item in decodedList) {
            try {
              if (item is Map<String, dynamic>) {
                loadedList.add(Player.fromJson(item));
              } else if (item is Map) {
                loadedList.add(Player.fromJson(Map<String, dynamic>.from(item)));
              }
            } catch (err) {
              debugPrint('Error decoding individual player: $err');
            }
          }
        } catch (jsonErr) {
          debugPrint('Error parsing saved players json: $jsonErr');
        }
      }

      // Nếu chưa có dữ liệu lưu trữ, khởi tạo từ MockData mặc định
      if (loadedList.isEmpty && (savedJson == null || savedJson.isEmpty)) {
        loadedList = List.from(MockData.players);
      }

      // 2. Phục hồi avatar riêng cho từng cầu thủ (bảo đảm 100% không bao giờ mất sau khi restart)
      for (int i = 0; i < loadedList.length; i++) {
        final p = loadedList[i];
        final savedAvatar = prefs.getString('lfc_avatar_${p.id}');
        if (savedAvatar != null && savedAvatar.trim().isNotEmpty) {
          loadedList[i] = p.copyWith(avatarUrl: savedAvatar.trim());
        }
      }

      _players = loadedList;
      if (_selectedPlayer != null) {
        _selectedPlayer = _players.firstWhere(
          (p) => p.id == _selectedPlayer!.id,
          orElse: () => _players.isNotEmpty ? _players.first : null as dynamic,
        );
      }
    } catch (e) {
      debugPrint('Error loading saved players: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// LUỒNG 2: LƯU TRỮ DỮ LIỆU VÀO BỘ NHỚ MÁY (SharedPreferences)
  /// - Chuyển toàn bộ danh sách `_players` sang dạng chuỗi JSON
  /// - Ghi vào bộ nhớ máy để bảo đảm khi tắt/mở lại app dữ liệu vẫn nguyên vẹn
  Future<void> _savePlayersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Lưu toàn bộ danh sách cầu thủ dạng JSON
      final jsonList = _players.map((p) => p.toJson()).toList();
      await prefs.setString(_playersStorageKey, jsonEncode(jsonList));

      // Lưu avatar riêng của từng cầu thủ để bảo đảm không bao giờ mất
      for (final p in _players) {
        if (p.avatarUrl.trim().isNotEmpty) {
          await prefs.setString('lfc_avatar_${p.id}', p.avatarUrl.trim());
        }
      }
    } catch (e) {
      debugPrint('Error saving players to storage: $e');
    }
  }

  /// Cập nhật bộ lọc vị trí thi đấu và thông báo cho giao diện vẽ lại
  void setPositionFilter(String filter) {
    _selectedPositionFilter = filter;
    notifyListeners();
  }

  /// Cập nhật từ khóa tìm kiếm và thông báo cho giao diện vẽ lại
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Chọn một cầu thủ cụ thể làm cầu thủ tiêu điểm
  void selectPlayer(Player player) {
    _selectedPlayer = player;
    notifyListeners();
  }

  /// LUỒNG 3: THÊM MỚI CẦU THỦ (CREATE)
  /// - Đưa đối tượng Player mới vào danh sách `_players`
  /// - Kích hoạt `notifyListeners()` để UI cập nhật thẻ mới
  /// - Đồng bộ lưu dữ liệu xuống bộ nhớ SharedPreferences
  Future<void> addPlayer(Player player) async {
    _players.add(player);
    notifyListeners();
    await _savePlayersToStorage();
  }

  /// LUỒNG 4: CẬP NHẬT / CHỈNH SỬA THÔNG TIN CẦU THỦ (UPDATE)
  /// - Tìm vị trí index của cầu thủ theo ID
  /// - Ghi đè thông tin mới lên vị trí đó
  /// - Kích hoạt `notifyListeners()` để màn hình chi tiết và danh sách cập nhật
  /// - Đồng bộ lưu dữ liệu xuống bộ nhớ SharedPreferences
  Future<void> updatePlayer(Player player) async {
    final index = _players.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      _players[index] = player;
      if (_selectedPlayer?.id == player.id) {
        _selectedPlayer = player;
      }
      notifyListeners();
      await _savePlayersToStorage();
    }
  }

  /// LUỒNG 5: XÓA CẦU THỦ (DELETE)
  /// - Tìm index và gỡ cầu thủ khỏi danh sách `_players`
  /// - Cập nhật lại UI thông qua `notifyListeners()`
  /// - Ghi đè danh sách mới vào bộ nhớ SharedPreferences
  /// - TRẢ VỀ đối tượng Player đã xóa để màn hình có thể hỗ trợ nút "HOÀN TÁC (UNDO)"
  Future<Player?> deletePlayer(String id) async {
    final index = _players.indexWhere((p) => p.id == id);
    if (index == -1) return null;
    final removed = _players.removeAt(index);
    if (_selectedPlayer?.id == id) {
      _selectedPlayer = _players.isNotEmpty ? _players.first : null;
    }
    notifyListeners();
    await _savePlayersToStorage();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lfc_avatar_$id');
    } catch (_) {}
    return removed;
  }

  /// LUỒNG 6: KHÔI PHỤC CẦU THỦ (UNDO RESTORE)
  /// - Chèn lại cầu thủ vào đúng vị trí index trước khi xóa
  /// - Thông báo cho UI và lưu lại vào SharedPreferences
  Future<void> restorePlayer(int index, Player player) async {
    if (index < 0 || index > _players.length) {
      _players.add(player);
    } else {
      _players.insert(index, player);
    }
    notifyListeners();
    await _savePlayersToStorage();
    if (player.avatarUrl.trim().isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lfc_avatar_${player.id}', player.avatarUrl.trim());
      } catch (_) {}
    }
  }

  /// Thêm buổi tập luyện mới cho đội
  void addTrainingSession(TrainingSession session) {
    _trainings.add(session);
    notifyListeners();
  }

  /// LUỒNG 7: KHÔI PHỤC ĐỘI HÌNH GỐC (RESET TO DEFAULT)
  /// - Xóa toàn bộ dữ liệu tùy chỉnh trong SharedPreferences
  /// - Đặt lại danh sách 25 cầu thủ nguyên bản từ MockData
  Future<void> resetToDefaultMockData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playersStorageKey);
    for (final p in MockData.players) {
      await prefs.remove('lfc_avatar_${p.id}');
    }
    _players = List.from(MockData.players);
    _selectedPlayer = _players.isNotEmpty ? _players.first : null;
    notifyListeners();
  }
}
