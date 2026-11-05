import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';
import '../models/training_session.dart';
import '../models/sponsor_campaign.dart';
import '../models/sponsorship.dart';
import '../models/user_profile.dart';
import '../data/mock_data.dart';
import '../data/training_schedule_data.dart';
import '../services/api_service.dart';

class AppStateProvider extends ChangeNotifier {
  static const String _playersStorageKey = 'lfc_players_data_v1';
  static const String _trainingsStorageKey = 'lfc_trainings_data_v1';
  static const String _campaignsStorageKey = 'lfc_campaigns_data_v1';
  static const String _sponsorshipsStorageKey = 'lfc_sponsorships_data_v1';
  static const String _themeModeStorageKey = 'lfc_theme_mode_v1';
  static const String _userProfileStorageKey = 'lfc_user_profile_data_v1';

  static List<TrainingSession> _getDefaultTrainings() {
    final list = List<TrainingSession>.from(TrainingScheduleData.sessions);
    for (final s in MockData.trainingSessions) {
      if (!list.any((e) => e.id == s.id)) {
        list.add(s);
      }
    }
    return list;
  }

  List<Player> _players = List.from(MockData.players);
  List<TrainingSession> _trainings = _getDefaultTrainings();
  List<SponsorCampaign> _campaigns = List.from(MockData.sponsorCampaigns);
  List<Sponsorship> _sponsorships = List.from(MockData.sponsorships);

  ThemeMode _themeMode = ThemeMode.dark;

  UserProfile _userProfile = UserProfile.defaultProfile();
  bool _isLoggedIn = false;

  String _selectedPositionFilter = 'All';
  String _searchQuery = '';
  Player? _selectedPlayer;
  bool _isInitialized = false;
  bool _isBackendConnected = false;
  bool _isSyncing = false;
  bool _campaignsLoading = true;
  bool _sponsorshipsLoading = true;
  String? _campaignsError;
  String? _sponsorshipsError;
  DateTime? _lastSyncTime;

  AppStateProvider() {
    _loadAllData();
  }

  List<Player> get players => _players;
  List<TrainingSession> get trainings => _trainings;
  List<SponsorCampaign> get campaigns => _campaigns;
  List<Sponsorship> get sponsorships => _sponsorships;
  bool get campaignsLoading => _campaignsLoading;
  bool get sponsorshipsLoading => _sponsorshipsLoading;
  String? get campaignsError => _campaignsError;
  String? get sponsorshipsError => _sponsorshipsError;
  String get selectedPositionFilter => _selectedPositionFilter;
  String get searchQuery => _searchQuery;
  Player? get selectedPlayer =>
      _selectedPlayer ?? (_players.isNotEmpty ? _players.first : null);
  bool get isInitialized => _isInitialized;
  bool get isBackendConnected => _isBackendConnected;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  UserProfile get userProfile => _userProfile;
  bool get isLoggedIn => _isLoggedIn;

  List<Player> get filteredPlayers {
    return _players.where((player) {
      final matchesPosition =
          _selectedPositionFilter == 'All' ||
          player.position.name.toLowerCase() ==
              _selectedPositionFilter.toLowerCase();
      final matchesSearch =
          player.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          player.nationality.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          player.number.toString().contains(_searchQuery);
      return matchesPosition && matchesSearch;
    }).toList();
  }

  double get totalMarketValue {
    return _players.fold(0.0, (sum, player) => sum + player.currentMarketValue);
  }

  double get averageRating {
    if (_players.isEmpty) return 0.0;
    final total = _players.fold(
      0.0,
      (sum, player) => sum + player.overallRating,
    );
    return total / _players.length;
  }

  Future<void> _loadAllData() async {
    try {

      await _loadThemeModeFromLocalStorage();
      await _loadUserProfile();

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

      await _loadTrainingsFromLocalStorage();
      await reloadCommercialData();
    } catch (e) {
      debugPrint('[AppState] Lỗi khởi tạo: $e');
      await _loadPlayersFromLocalStorage();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadThemeModeFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_themeModeStorageKey);
      if (modeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeModeStorageKey,
        _themeMode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {}
  }

  Future<void> _loadUserProfile() async {
    try {

      final remoteProfile = await ApiService.fetchUserProfile();
      if (remoteProfile != null) {
        _userProfile = remoteProfile;
        await _saveUserProfileToLocalStorage();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_userProfileStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final loaded = UserProfile.fromJson(jsonDecode(savedJson) as Map<String, dynamic>);
        if (loaded.avatarUrl.contains('images.unsplash.com') || loaded.avatarUrl.isEmpty) {
          _userProfile = loaded.copyWith(avatarUrl: 'assets/images/john.jpg');
        } else {
          _userProfile = loaded;
        }
      }
    } catch (e) {
      debugPrint('[AppState] Lỗi nạp user profile: $e');
    }
  }

  Future<void> _saveUserProfileToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userProfileStorageKey, jsonEncode(_userProfile.toJson()));
    } catch (_) {}
  }

  Future<void> updateUserProfile(UserProfile updated) async {
    _userProfile = updated;
    notifyListeners();
    await _saveUserProfileToLocalStorage();
    await ApiService.updateUserProfile(updated);
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    return await ApiService.changePassword(currentPassword, newPassword);
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
            Player p;
            if (item is Map<String, dynamic>) {
              p = Player.fromJson(item);
            } else if (item is Map) {
              p = Player.fromJson(Map<String, dynamic>.from(item));
            } else {
              continue;
            }

            final defaultPlayer = MockData.players.cast<Player?>().firstWhere(
                  (def) => def?.id == p.id,
                  orElse: () => null,
                );
            if (defaultPlayer != null &&
                (p.avatarUrl.contains('images.unsplash.com') || p.avatarUrl.isEmpty)) {
              p = p.copyWith(avatarUrl: defaultPlayer.avatarUrl);
            }
            playerMap[p.id] = p;
          } catch (_) {}
        }
      }

      for (final id in playerMap.keys) {
        final savedAvatar = prefs.getString('lfc_avatar_$id');
        if (savedAvatar != null &&
            savedAvatar.trim().isNotEmpty &&
            !savedAvatar.contains('images.unsplash.com')) {
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
      final encoded = jsonEncode(_players.map((p) => p.toJson()).toList());
      await prefs.setString(_playersStorageKey, encoded);

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
        _trainings = list
            .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveTrainingsToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_trainings.map((t) => t.toJson()).toList());
      await prefs.setString(_trainingsStorageKey, encoded);
    } catch (_) {}
  }

  Future<void> _loadCampaignsFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_campaignsStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        _campaigns = list
            .map(
              (item) =>
                  SponsorCampaign.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
            )
            .toList();
      } else {
        _campaigns = List.from(MockData.sponsorCampaigns);
      }
    } catch (e) {
      debugPrint('[AppState] Lỗi đọc campaigns local: $e');
      _campaigns = List.from(MockData.sponsorCampaigns);
    }
  }

  Future<void> _saveCampaignsToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_campaigns.map((c) => c.toJson()).toList());
      await prefs.setString(_campaignsStorageKey, encoded);
    } catch (_) {}
  }

  Future<void> _loadSponsorshipsFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_sponsorshipsStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson);
        _sponsorships = list
            .map(
              (item) =>
                  Sponsorship.fromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } else {
        _sponsorships = List.from(MockData.sponsorships);
      }
    } catch (e) {
      debugPrint('[AppState] Lỗi đọc sponsorship local: $e');
      _sponsorships = List.from(MockData.sponsorships);
    }
  }

  Future<void> _saveSponsorshipsToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_sponsorships.map((s) => s.toJson()).toList());
      await prefs.setString(_sponsorshipsStorageKey, encoded);
    } catch (_) {}
  }

  Future<void> reloadCommercialData() async {
    await Future.wait([_reloadCampaigns(), _reloadSponsorships()]);
  }

  Future<void> _reloadCampaigns() async {
    _campaignsLoading = true;
    _campaignsError = null;
    notifyListeners();
    try {
      _campaigns = await ApiService.fetchCampaigns();
      await _saveCampaignsToLocalStorage();
    } catch (error) {
      await _loadCampaignsFromLocalStorage();
      _campaignsError = error.toString();
    } finally {
      _campaignsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadSponsorships() async {
    _sponsorshipsLoading = true;
    _sponsorshipsError = null;
    notifyListeners();
    try {
      _sponsorships = await ApiService.fetchSponsorships();
      await _saveSponsorshipsToLocalStorage();
    } catch (error) {
      await _loadSponsorshipsFromLocalStorage();
      _sponsorshipsError = error.toString();
    } finally {
      _sponsorshipsLoading = false;
      notifyListeners();
    }
  }

  void setPositionFilter(String position) {
    _selectedPositionFilter = position;
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

  Future<void> addPlayer(Player player) async {
    _players.insert(0, player);
    notifyListeners();
    await _savePlayersToLocalStorage();
    ApiService.addPlayer(player);
  }

  Future<Player?> deletePlayer(String id) async {
    final index = _players.indexWhere((p) => p.id == id);
    if (index == -1) return null;
    final removed = _players.removeAt(index);
    if (_selectedPlayer?.id == id) {
      _selectedPlayer = _players.isNotEmpty ? _players.first : null;
    }
    notifyListeners();
    await _savePlayersToLocalStorage();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lfc_avatar_$id');
    } catch (_) {}
    ApiService.deletePlayer(id);
    return removed;
  }

  Future<void> restorePlayer(int index, Player player) async {
    if (index < 0 || index > _players.length) {
      _players.add(player);
    } else {
      _players.insert(index, player);
    }
    notifyListeners();
    await _savePlayersToLocalStorage();
    if (player.avatarUrl.trim().isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'lfc_avatar_${player.id}',
          player.avatarUrl.trim(),
        );
      } catch (_) {}
    }
    ApiService.addPlayer(player);
  }

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

  Future<void> completeTrainingSession(String id) async {
    final index = _trainings.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _trainings[index];
      _trainings[index] = current.copyWith(status: 'Completed');

      for (final playerId in current.playerIds) {
        final pIdx = _players.indexWhere((p) => p.id == playerId);
        if (pIdx != -1) {
          final p = _players[pIdx];
          final newAttrs = Map<String, double>.from(p.attributes);
          final oldStamina =
              (newAttrs['stamina'] as num?)?.toDouble() ??
              (newAttrs['physical'] as num?)?.toDouble() ??
              80.0;
          final updatedVal = min(99.0, oldStamina + 0.5);
          if (newAttrs.containsKey('stamina')) {
            newAttrs['stamina'] = updatedVal;
          } else {
            newAttrs['physical'] = updatedVal;
          }
          final updatedHistory = List<PlayerStatistic>.from(p.progressHistory);
          if (updatedHistory.isNotEmpty) {
            final last = updatedHistory.removeLast();
            updatedHistory.add(PlayerStatistic(date: last.date, attributes: newAttrs));
          } else {
            updatedHistory.add(PlayerStatistic(date: '2024-10', attributes: newAttrs));
          }
          _players[pIdx] = p.copyWith(progressHistory: updatedHistory);
          ApiService.updatePlayer(_players[pIdx]);
        }
      }
      notifyListeners();
      await _saveTrainingsToLocalStorage();
      await _savePlayersToLocalStorage();
    }
  }

  Future<void> addCampaign(SponsorCampaign campaign) async {
    var itemToSave = campaign;
    try {
      itemToSave = await ApiService.addCampaign(campaign);
    } catch (e) {
      debugPrint('[AppState] Thêm chiến dịch offline: $e');
    }
    _campaigns.insert(0, itemToSave);
    _campaignsError = null;
    notifyListeners();
    await _saveCampaignsToLocalStorage();
  }

  Future<void> updateCampaign(SponsorCampaign campaign) async {
    var itemToSave = campaign;
    try {
      itemToSave = await ApiService.updateCampaign(campaign);
    } catch (e) {
      debugPrint('[AppState] Cập nhật chiến dịch offline: $e');
    }
    final index = _campaigns.indexWhere((c) => c.id == itemToSave.id);
    if (index == -1) {
      _campaigns.insert(0, itemToSave);
    } else {
      _campaigns[index] = itemToSave;
    }
    _campaignsError = null;
    notifyListeners();
    await _saveCampaignsToLocalStorage();
  }

  Future<void> deleteCampaign(String id) async {
    try {
      await ApiService.deleteCampaign(id);
    } catch (e) {
      debugPrint('[AppState] Xóa chiến dịch offline: $e');
    }
    _campaigns.removeWhere((c) => c.id == id);
    _campaignsError = null;
    notifyListeners();
    await _saveCampaignsToLocalStorage();
  }

  Future<void> addSponsorship(Sponsorship sponsorship) async {
    var itemToSave = sponsorship;
    try {
      itemToSave = await ApiService.addSponsorship(sponsorship);
    } catch (e) {
      debugPrint('[AppState] Thêm nhà tài trợ offline: $e');
    }
    _sponsorships.insert(0, itemToSave);
    _sponsorshipsError = null;
    notifyListeners();
    await _saveSponsorshipsToLocalStorage();
  }

  Future<void> updateSponsorship(Sponsorship sponsorship) async {
    var itemToSave = sponsorship;
    try {
      itemToSave = await ApiService.updateSponsorship(sponsorship);
    } catch (e) {
      debugPrint('[AppState] Cập nhật nhà tài trợ offline: $e');
    }
    final index = _sponsorships.indexWhere((item) => item.id == itemToSave.id);
    if (index == -1) {
      _sponsorships.insert(0, itemToSave);
    } else {
      _sponsorships[index] = itemToSave;
    }
    _sponsorshipsError = null;
    notifyListeners();
    await _saveSponsorshipsToLocalStorage();
  }

  Future<void> deleteSponsorship(String id) async {
    try {
      await ApiService.deleteSponsorship(id);
    } catch (e) {
      debugPrint('[AppState] Xóa nhà tài trợ offline: $e');
    }
    _sponsorships.removeWhere((item) => item.id == id);
    _sponsorshipsError = null;
    notifyListeners();
    await _saveSponsorshipsToLocalStorage();
  }

  Future<void> syncRealtimeData() async {
    _isSyncing = true;
    notifyListeners();
    try {
      final backendPlayers = await ApiService.fetchPlayers();
      if (backendPlayers != null && backendPlayers.isNotEmpty) {
        _players = backendPlayers;
        _isBackendConnected = true;
      } else {
        final rand = Random();
        for (int i = 0; i < _players.length; i++) {
          final p = _players[i];
          final delta = (rand.nextDouble() * 3.0 - 1.2);
          final newVal = max(5.0, p.currentMarketValue + delta);
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
      await reloadCommercialData();
    } catch (e) {
      debugPrint('[AppState] Lỗi sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> registerAccount({
    required String fullName,
    required String email,
    required String password,
    String role = 'Club Official',
    String department = 'Executive Leadership',
  }) async {
    final registered = await ApiService.registerUser(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      department: department,
    );
    if (registered != null) {
      _userProfile = registered;
    } else {
      _userProfile = UserProfile(
        id: 'usr_',
        username: email.contains('@') ? email.split('@')[0] : email,
        fullName: fullName,
        email: email,
        phone: '+44 151 263 2361',
        role: role,
        department: department,
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
        bio: 'Official Registered Member of Liverpool FC.',
      );
    }
    _isLoggedIn = true;
    notifyListeners();
    await _saveUserProfileToLocalStorage();
    return true;
  }

  Future<bool> loginWithGoogle({required String email, required String fullName}) async {
    final user = await ApiService.loginWithGoogle(email: email, fullName: fullName);
    if (user != null) {
      _userProfile = user;
    } else {
      _userProfile = UserProfile(
        id: 'usr_google_',
        username: email.split('@')[0],
        fullName: fullName,
        email: email,
        phone: '+1 (617) 226-6000',
        role: 'Club Stakeholder & Official',
        department: 'Liverpool FC Executive Management',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
        bio: 'Authenticated via Google / Gmail Account.',
      );
    }
    _isLoggedIn = true;
    notifyListeners();
    await _saveUserProfileToLocalStorage();
    return true;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> resetToDefaultMockData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playersStorageKey);
    await prefs.remove(_trainingsStorageKey);
    await prefs.remove(_campaignsStorageKey);
    await prefs.remove(_sponsorshipsStorageKey);
    for (final p in MockData.players) {
      await prefs.remove('lfc_avatar_${p.id}');
    }

    final resetPlayers = await ApiService.resetToDefault();
    if (resetPlayers != null && resetPlayers.isNotEmpty) {
      _players = resetPlayers;
    } else {
      _players = List.from(MockData.players);
    }
    _trainings = _getDefaultTrainings();
    await reloadCommercialData();
    _selectedPlayer = _players.first;
    notifyListeners();
  }
}
