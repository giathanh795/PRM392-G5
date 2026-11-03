import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/sponsor_campaign.dart';
import '../models/player.dart';
import '../models/sponsorship.dart';

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

  // Lấy toàn bộ danh sách cầu thủ từ Backend Spring Boot
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

  // Cập nhật thông tin cầu thủ (đổi avatar, thêm video PR, sửa chỉ số)
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

  // Thêm cầu thủ mới
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

  // Xóa cầu thủ
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

  // Khôi phục danh sách Liverpool mặc định ban đầu
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

  static Future<List<SponsorCampaign>> fetchCampaigns() async {
    final response = await http
        .get(Uri.parse('$apiBaseUrl/campaigns'))
        .timeout(const Duration(seconds: 5));
    _ensureSuccess(response, const {200}, 'Tải chiến dịch');
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
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
    _ensureSuccess(response, const {200}, 'Tải nhà tài trợ');
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return list
        .map(
          (item) =>
              Sponsorship.fromJson(Map<String, dynamic>.from(item as Map)),
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

  static const _jsonHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

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
