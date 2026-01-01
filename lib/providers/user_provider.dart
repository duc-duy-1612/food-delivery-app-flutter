import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  // Hàm lưu user khi login thành công
  void setUser(UserModel user) {
    _user = user;
    notifyListeners(); // Báo cho toàn bộ app biết user đã thay đổi
  }

  // Hàm đăng xuất
  void logout() {
    _user = null;
    notifyListeners();
  }
}
