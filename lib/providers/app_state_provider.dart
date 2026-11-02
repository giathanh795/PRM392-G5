import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/training_session.dart';
import '../models/sponsor_campaign.dart';
import '../data/mock_data.dart';

class AppStateProvider extends ChangeNotifier {
  static const String _playersStorageKey = 'lfc_players_data_v1';
  
  List<Player> _players = List.from(MockData.players);
  final List<TrainingSession> _trainings = List.from(MockData.trainingSessions);
  final List<SponsorCampaign> _campaigns = List.from(MockData.sponsorCampaigns);
  
  String _selectedPositionFilter = 'All';
  String _searchQuery = '';
  Player? _selectedPlayer;
  bool _isInitialized = false;

  AppStateProvider() {
    _loadPlayersFromStorage();
  }

  List<Player> get players => _players;
  List<TrainingSession> get trainings => _trainings;
  List<SponsorCampaign> get campaigns => _campaigns;
  String get selectedPositionFilter => _selectedPositionFilter;
  String get searchQuery => _searchQuery;
  Player? get selectedPlayer => _selectedPlayer ?? (_players.isNotEmpty ? _players.first : null);
  bool get isInitialized => _isInitialized;

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

  double get totalMarketValue {
    return _players.fold(0.0, (sum, p) => sum + p.currentMarketValue);
  }

  // Nạp dữ liệu đã lưu từ SharedPreferences (Dual-layer: Full squad merge + Direct avatar map)
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

  // Lưu danh sách người chơi vào bộ nhớ máy (SharedPreferences)
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

  void setPositionFilter(String filter) {
    _selectedPositionFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectPlayer(Player player) {
    _selectedPlayer = player;
    notifyListeners();
  }

  Future<void> addPlayer(Player player) async {
    _players.add(player);
    notifyListeners();
    await _savePlayersToStorage();
  }

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

  // Xóa cầu thủ khỏi danh sách và lưu vào storage, trả về cầu thủ đã xóa để hỗ trợ Hoàn tác
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

  // Khôi phục lại cầu thủ vừa xóa (Hoàn tác)
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

  void addTrainingSession(TrainingSession session) {
    _trainings.add(session);
    notifyListeners();
  }

  // Khôi phục lại toàn bộ dữ liệu mặc định ban đầu
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
