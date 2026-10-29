import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/training_session.dart';
import '../models/sponsor_campaign.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';

class AppStateProvider extends ChangeNotifier {
  static const String _playersStorageKey = 'lfc_players_data_v1';
  static const String _trainingsStorageKey = 'lfc_trainings_data_v1';
  static const String _campaignsStorageKey = 'lfc_campaigns_data_v1';
  
  List<Player> _players = List.from(MockData.players);
  List<TrainingSession> _trainings = List.from(MockData.trainingSessions);
  List<SponsorCampaign> _campaigns = List.from(MockData.sponsorCampaigns);
  
  String _selectedPositionFilter = 'All';
  String _searchQuery = '';
  Player? _selectedPlayer;
  bool _isInitialized = false;
  bool _isBackendConnected = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  AppStateProvider() {
    _loadAllData();
  }

  List<Player> get players => _players;
  List<TrainingSession> get trainings => _trainings;
  List<SponsorCampaign> get campaigns => _campaigns;
  String get selectedPositionFilter => _selectedPositionFilter;
  String get searchQuery => _searchQuery;
  Player? get selectedPlayer => _selectedPlayer ?? (_players.isNotEmpty ? _players.first : null);
  bool get isInitialized => _isInitialized;
  bool get isBackendConnected => _isBackendConnected;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

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

  // --- NẠP DỮ LIỆU ---
  Future<void> _loadAllData() async {
    try {
      // 1. Thử lấy Players từ Backend
      final backendPlayers = await ApiService.fetchPlayers();
      if (backendPlayers != null && backendPlayers.isNotEmpty) {
        _players = backendPlayers;
        _isBackendConnected = true;
        _lastSyncTime = DateTime.now();
        await _savePlayersToLocalStorage();
      } else {
        _isBackendConnected = false;
        await _loadPlayersFromLocalStorage();
      }

      // 2. Nạp Trainings & Campaigns từ LocalStorage (nếu đã lưu tùy chỉnh)
      await _loadTrainingsFromLocalStorage();
      await _loadCampaignsFromLocalStorage();
    } catch (e) {
      debugPrint('[AppState] Lỗi khởi tạo: $e');
      await _loadPlayersFromLocalStorage();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadPlayersFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, Player> playerMap = {
        for (var p in MockData.players) p.id: p,
      };

      final savedJson = prefs.getString(_playersStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(savedJson);
        for (final item in decodedList) {
          try {
            if (item is Map<String, dynamic>) {
              final p = Player.fromJson(item);
              playerMap[p.id] = p;
            } else if (item is Map) {
              final p = Player.fromJson(Map<String, dynamic>.from(item));
              playerMap[p.id] = p;
            }
          } catch (_) {}
        }
      }

      for (final id in playerMap.keys) {
        final savedAvatar = prefs.getString('lfc_avatar_$id');
        if (savedAvatar != null && savedAvatar.trim().isNotEmpty) {
          playerMap[id] = playerMap[id]!.copyWith(avatarUrl: savedAvatar.trim());
        }
      }

      _players = playerMap.values.toList();
      if (_selectedPlayer != null) {
        _selectedPlayer = _players.firstWhere(
          (p) => p.id == _selectedPlayer!.id,
          orElse: () => _players.first,
        );
      }
    } catch (e) {
      debugPrint('[AppState] Lỗi đọc players local: $e');
    }
  }

  Future<void> _savePlayersToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _players.map((p) => p.toJson()).toList();
      await prefs.setString(_playersStorageKey, jsonEncode(jsonList));

      for (final p in _players) {
        if (p.avatarUrl.trim().isNotEmpty) {
          await prefs.setString('lfc_avatar_${p.id}', p.avatarUrl.trim());
        }
      }
    } catch (e) {
      debugPrint('[AppState] Lỗi ghi players local: $e');
    }
  }

  Future<void> _loadTrainingsFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_trainingsStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        _trainings = list.map((e) => TrainingSession.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveTrainingsToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _trainings.map((t) => t.toJson()).toList();
      await prefs.setString(_trainingsStorageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _loadCampaignsFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_campaignsStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        _campaigns = list.map((e) => SponsorCampaign.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveCampaignsToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _campaigns.map((c) => c.toJson()).toList();
      await prefs.setString(_campaignsStorageKey, jsonEncode(jsonList));
    } catch (_) {}
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

  // --- QUẢN LÝ CẦU THỦ (PLAYER CRUD & EDITING) ---
  Future<void> addPlayer(Player player) async {
    _players.add(player);
    notifyListeners();
    await _savePlayersToLocalStorage();
    ApiService.addPlayer(player);
  }

  Future<void> updatePlayer(Player player) async {
    final index = _players.indexWhere((p) => p.id == player.id);
    if (index != -1) {
      _players[index] = player;
      if (_selectedPlayer?.id == player.id) {
        _selectedPlayer = player;
      }
      notifyListeners();
      await _savePlayersToLocalStorage();
      ApiService.updatePlayer(player);
    }
  }

  Future<void> deletePlayer(String id) async {
    _players.removeWhere((p) => p.id == id);
    if (_selectedPlayer?.id == id) {
      _selectedPlayer = _players.isNotEmpty ? _players.first : null;
    }
    notifyListeners();
    await _savePlayersToLocalStorage();
    ApiService.deletePlayer(id);
  }

  // --- QUẢN LÝ TRAINING (TRAINING CRUD & ATTENDANCE) ---
  Future<void> addTrainingSession(TrainingSession session) async {
    _trainings.insert(0, session);
    notifyListeners();
    await _saveTrainingsToLocalStorage();
  }

  Future<void> updateTrainingSession(TrainingSession session) async {
    final index = _trainings.indexWhere((t) => t.id == session.id);
    if (index != -1) {
      _trainings[index] = session;
      notifyListeners();
      await _saveTrainingsToLocalStorage();
    }
  }

  Future<void> deleteTrainingSession(String id) async {
    _trainings.removeWhere((t) => t.id == id);
    notifyListeners();
    await _saveTrainingsToLocalStorage();
  }

  // Đổi trạng thái buổi tập (Upcoming -> Completed) và tự cộng chỉ số thể lực cho cầu thủ tham gia
  Future<void> completeTrainingSession(String id) async {
    final index = _trainings.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _trainings[index];
      _trainings[index] = current.copyWith(status: 'Completed');
      
      // Tăng nhẹ 0.5 chỉ số thể lực cho cầu thủ tham gia
      for (final playerId in current.playerIds) {
        final pIdx = _players.indexWhere((p) => p.id == playerId);
        if (pIdx != -1) {
          final p = _players[pIdx];
          if (p.progressHistory.isNotEmpty) {
            final latest = Map<String, double>.from(p.progressHistory.last.attributes);
            if (latest.containsKey('Physical')) {
              latest['Physical'] = (latest['Physical']! + 0.5).clamp(40.0, 99.0);
            }
            if (latest.containsKey('Stamina')) {
              latest['Stamina'] = (latest['Stamina']! + 0.5).clamp(40.0, 99.0);
            }
            final updatedHist = List<PlayerStatistic>.from(p.progressHistory);
            updatedHist[updatedHist.length - 1] = PlayerStatistic(
              date: p.progressHistory.last.date,
              attributes: latest,
            );
            _players[pIdx] = p.copyWith(progressHistory: updatedHist);
          }
        }
      }
      notifyListeners();
      await _saveTrainingsToLocalStorage();
      await _savePlayersToLocalStorage();
    }
  }

  // --- QUẢN LÝ COMMERCIAL (SPONSOR & ADIDAS CAMPAIGN CRUD) ---
  Future<void> addCampaign(SponsorCampaign campaign) async {
    _campaigns.insert(0, campaign);
    notifyListeners();
    await _saveCampaignsToLocalStorage();
  }

  Future<void> updateCampaign(SponsorCampaign campaign) async {
    final index = _campaigns.indexWhere((c) => c.id == campaign.id);
    if (index != -1) {
      _campaigns[index] = campaign;
      notifyListeners();
      await _saveCampaignsToLocalStorage();
    }
  }

  Future<void> deleteCampaign(String id) async {
    _campaigns.removeWhere((c) => c.id == id);
    notifyListeners();
    await _saveCampaignsToLocalStorage();
  }

  // --- ĐỒNG BỘ THỜI GIAN THỰC TỪ TRỰC TIẾP (LIVE DATA SYNC) ---
  // Tự động kết nối Backend hoặc mô phỏng cập nhật phong độ, giá trị thị trường và tình trạng chấn thương
  Future<void> syncRealtimeData() async {
    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Thử refresh từ Backend
      final backendPlayers = await ApiService.fetchPlayers();
      if (backendPlayers != null && backendPlayers.isNotEmpty) {
        _players = backendPlayers;
        _isBackendConnected = true;
      } else {
        // 2. Mô phỏng cập nhật thuật toán thị trường & thể lực Premier League 2026/2027
        await Future.delayed(const Duration(milliseconds: 1200));
        final rng = Random();
        for (int i = 0; i < _players.length; i++) {
          final p = _players[i];
          // Biến động giá trị thị trường nhỏ theo phong độ (-2M đến +3M)
          final delta = (rng.nextDouble() * 5.0 - 2.0);
          final newVal = (p.currentMarketValue + delta).clamp(10.0, 200.0);
          final roundedVal = double.parse(newVal.toStringAsFixed(1));
          
          final newHistory = List<MarketValuePoint>.from(p.marketValueHistory);
          if (newHistory.isNotEmpty) {
            newHistory[newHistory.length - 1] = MarketValuePoint(
              date: newHistory.last.date,
              valueInMillionsEuro: roundedVal,
            );
          }

          _players[i] = p.copyWith(
            previousMarketValue: p.currentMarketValue,
            currentMarketValue: roundedVal,
            marketValueHistory: newHistory,
          );
        }
      }
      _lastSyncTime = DateTime.now();
      await _savePlayersToLocalStorage();
    } catch (e) {
      debugPrint('[AppState] Lỗi sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Khôi phục mặc định ban đầu
  Future<void> resetToDefaultMockData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playersStorageKey);
    await prefs.remove(_trainingsStorageKey);
    await prefs.remove(_campaignsStorageKey);
    for (final p in MockData.players) {
      await prefs.remove('lfc_avatar_${p.id}');
    }

    final resetPlayers = await ApiService.resetToDefault();
    if (resetPlayers != null && resetPlayers.isNotEmpty) {
      _players = resetPlayers;
    } else {
      _players = List.from(MockData.players);
    }
    _trainings = List.from(MockData.trainingSessions);
    _campaigns = List.from(MockData.sponsorCampaigns);
    _selectedPlayer = _players.first;
    notifyListeners();
  }
}
