import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keySavedUsers = 'saved_users_history';

  // Lấy danh sách tài khoản đã lưu
  Future<List<Map<String, dynamic>>> getSavedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(_keySavedUsers);

    if (jsonList == null) return [];

    return jsonList.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  // Lưu tài khoản mới vào danh sách (Nếu trùng SĐT thì cập nhật)
  Future<void> saveUserToHistory(String phone, String password, String name, String? avatar) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> currentList = await getSavedUsers();

    // Xóa tài khoản cũ nếu trùng SĐT (để đưa cái mới nhất lên đầu)
    currentList.removeWhere((item) => item['phone'] == phone);

    // Tạo object mới
    Map<String, dynamic> newUser = {
      'phone': phone,
      'password': password,
      'name': name,
      'avatar': avatar ?? "",
      'time': DateTime.now().toIso8601String(),
    };

    // Thêm vào đầu danh sách
    currentList.insert(0, newUser);

    // Giới hạn chỉ lưu 5 tài khoản gần nhất
    if (currentList.length > 5) {
      currentList = currentList.sublist(0, 5);
    }

    // Lưu lại xuống máy
    List<String> jsonList = currentList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_keySavedUsers, jsonList);
  }

  // Xóa một tài khoản khỏi lịch sử
  Future<void> removeUserFromHistory(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> currentList = await getSavedUsers();

    currentList.removeWhere((item) => item['phone'] == phone);

    List<String> jsonList = currentList.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_keySavedUsers, jsonList);
  }
}
