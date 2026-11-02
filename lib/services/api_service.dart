import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/player.dart';

class ApiService {
  // Cấu hình URL linh hoạt:
  // - Web / Desktop / Thiết bị thật: http://localhost:8080/api/players
  // - Android Emulator: http://10.0.2.2:8080/api/players
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/players';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/players';
    }
    return 'http://localhost:8080/api/players';
  }

  // Lấy toàn bộ danh sách cầu thủ từ Backend Spring Boot
  static Future<List<Player>?> fetchPlayers() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((json) => Player.fromJson(json as Map<String, dynamic>)).toList();
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
        return list.map((json) => Player.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[ApiService] Lỗi khi gọi reset trên Backend: $e');
    }
    return null;
  }
}
