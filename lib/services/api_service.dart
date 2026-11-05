import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/sponsor_campaign.dart';
import '../models/player.dart';
import '../models/sponsorship.dart';
import '../models/user_profile.dart';

class ApiService {
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static String get baseUrl => '$apiBaseUrl/players';

  static Future<List<Player>?> fetchPlayers() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list
            .map((json) => Player.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('[ApiService] Server trả về mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiService] Không thể kết nối Backend ($baseUrl): $e');
    }
    return null;
  }

  static Future<bool> updatePlayer(Player player) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/${player.id}'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(player.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Lỗi khi cập nhật cầu thủ lên Backend: $e');
      return false;
    }
  }

  static Future<bool> addPlayer(Player player) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(player.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Lỗi khi thêm cầu thủ lên Backend: $e');
      return false;
    }
  }

  static Future<bool> deletePlayer(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/$id'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Lỗi khi xóa cầu thủ trên Backend: $e');
      return false;
    }
  }

  static Future<List<Player>?> resetToDefault() async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/reset'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list
            .map((json) => Player.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[ApiService] Lỗi khi gọi reset trên Backend: $e');
    }
    return null;
  }

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  static Future<List<SponsorCampaign>> fetchCampaigns() async {
    final response = await http
        .get(Uri.parse('$apiBaseUrl/campaigns'))
        .timeout(const Duration(seconds: 5));
    _ensureSuccess(response, const {200}, 'Tải danh sách chiến dịch');
    final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
    return list
        .map(
          (item) =>
              SponsorCampaign.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<SponsorCampaign> addCampaign(SponsorCampaign campaign) async {
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl/campaigns'),
          headers: _jsonHeaders,
          body: jsonEncode(campaign.toJson()),
        )
        .timeout(const Duration(seconds: 5));
    return _campaignResponse(response, const {200, 201}, 'Tạo chiến dịch');
  }

  static Future<SponsorCampaign> updateCampaign(
    SponsorCampaign campaign,
  ) async {
    final response = await http
        .put(
          Uri.parse(
            '$apiBaseUrl/campaigns/${Uri.encodeComponent(campaign.id)}',
          ),
          headers: _jsonHeaders,
          body: jsonEncode(campaign.toJson()),
        )
        .timeout(const Duration(seconds: 5));
    return _campaignResponse(response, const {200}, 'Cập nhật chiến dịch');
  }

  static Future<void> deleteCampaign(String id) async {
    final response = await http
        .delete(Uri.parse('$apiBaseUrl/campaigns/${Uri.encodeComponent(id)}'))
        .timeout(const Duration(seconds: 5));
    _ensureSuccess(response, const {200, 204}, 'Xóa chiến dịch');
  }

  static Future<List<Sponsorship>> fetchSponsorships() async {
    final response = await http
        .get(Uri.parse('$apiBaseUrl/sponsorships'))
        .timeout(const Duration(seconds: 5));
    _ensureSuccess(response, const {200}, 'Tải danh sách nhà tài trợ');
    final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
    return list
        .map(
          (item) => Sponsorship.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<Sponsorship> addSponsorship(Sponsorship sponsorship) async {
    return _sendSponsorship(sponsorship, 'POST', 'Tạo nhà tài trợ');
  }

  static Future<Sponsorship> updateSponsorship(Sponsorship sponsorship) async {
    return _sendSponsorship(sponsorship, 'PUT', 'Cập nhật nhà tài trợ');
  }

  static Future<void> deleteSponsorship(String id) async {
    final response = await http
        .delete(
          Uri.parse('$apiBaseUrl/sponsorships/${Uri.encodeComponent(id)}'),
        )
        .timeout(const Duration(seconds: 5));
    _ensureSuccess(response, const {200, 204}, 'Xóa nhà tài trợ');
  }

  static String sponsorshipContractUrl(String id) =>
      '$apiBaseUrl/sponsorships/${Uri.encodeComponent(id)}/contract';

  static Future<UserProfile?> fetchUserProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/user/profile'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return UserProfile.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('[ApiService] Không thể tải user profile từ SQL Backend: $e');
    }
    return null;
  }

  static Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      final response = await http
          .put(
            Uri.parse('$apiBaseUrl/user/profile'),
            headers: _jsonHeaders,
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Lỗi cập nhật user profile: $e');
      return false;
    }
  }

  static Future<UserProfile?> registerUser({
    required String fullName,
    required String email,
    required String password,
    String role = 'Club Official',
    String department = 'Executive Leadership',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('/user/register'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'fullName': fullName,
              'email': email,
              'password': password,
              'role': role,
              'department': department,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (data['user'] != null) {
          return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Lỗi đăng ký tài khoản: ');
    }
    return null;
  }

  static Future<UserProfile?> loginWithGoogle({
    required String email,
    required String fullName,
    String avatarUrl = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('/user/google-login'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'email': email,
              'fullName': fullName,
              'avatarUrl': avatarUrl,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (data['user'] != null) {
          return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Lỗi đăng nhập Google: ');
    }
    return null;
  }

  static Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/user/change-password'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Lỗi đổi mật khẩu: $e');
      return false;
    }
  }

  static Future<SponsorCampaign> _campaignResponse(
    http.Response response,
    Set<int> acceptedCodes,
    String action,
  ) {
    _ensureSuccess(response, acceptedCodes, action);
    return Future.value(
      SponsorCampaign.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      ),
    );
  }

  static Future<Sponsorship> _sendSponsorship(
    Sponsorship sponsorship,
    String method,
    String action,
  ) async {
    final isCreate = method == 'POST';
    final url = isCreate
        ? '$apiBaseUrl/sponsorships'
        : '$apiBaseUrl/sponsorships/${Uri.encodeComponent(sponsorship.id)}';
    final request = http.MultipartRequest(method, Uri.parse(url))
      ..fields['sponsorship'] = jsonEncode(sponsorship.toJson());
    if (sponsorship.contractFileData.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'contract',
          base64Decode(sponsorship.contractFileData),
          filename: sponsorship.contractFileName,
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 10),
    );
    final response = await http.Response.fromStream(streamedResponse);
    _ensureSuccess(response, isCreate ? const {200, 201} : const {200}, action);
    return Sponsorship.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  static void _ensureSuccess(
    http.Response response,
    Set<int> acceptedCodes,
    String action,
  ) {
    if (acceptedCodes.contains(response.statusCode)) return;
    final body = utf8.decode(response.bodyBytes).trim();
    throw ApiException(
      '$action thất bại (${response.statusCode})'
      '${body.isEmpty ? '' : ': $body'}',
    );
  }
}

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}
