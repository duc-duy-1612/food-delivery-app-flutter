import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/food_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';

class ApiService {
  final String baseUrl = "https://695224093b3c518fca119108.mockapi.io";

  // GIẢI PHÁP CHUNG: Hàm giải mã body thủ công bằng UTF-8
  List<dynamic> _decodeBody(http.Response response) {
    // Lấy byte của body và giải mã bằng utf8.decode
    var decodedBody = utf8.decode(response.bodyBytes);
    return jsonDecode(decodedBody);
  }

  // ==================== 1. USER & AUTH ====================

  Future<bool> checkUserExist(String phone) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users?phone=$phone'));
      if (response.statusCode == 200) {
        List<dynamic> body = _decodeBody(response); // SỬA Ở ĐÂY
        return body.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerUser(UserModel user) async {
    try {
      bool exists = await checkUserExist(user.phone ?? "");
      if (exists) {
        return false;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(user.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> login(String phone, String password) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        List<dynamic> body = _decodeBody(response); // SỬA Ở ĐÂY
        List<UserModel> users = body.map((e) => UserModel.fromJson(e)).toList();
        try {
          return users.firstWhere((u) {
            bool phoneMatch = u.phone.toString().trim() == phone.trim();
            bool passMatch = u.password.toString().trim() == password.trim();
            return phoneMatch && passMatch;
          });
        } catch (e) {
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(user.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== 2. FOODS & CATEGORIES ====================

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        List<dynamic> body = _decodeBody(response); // SỬA Ở ĐÂY
        return body.map((e) => CategoryModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<FoodModel>> getFoods() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/foods'));
      if (response.statusCode == 200) {
        List<dynamic> body = _decodeBody(response); // SỬA Ở ĐÂY
        return body.map((e) => FoodModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Các hàm khác không cần sửa vì nó gọi lại hàm trên

  // ==================== 3. ORDERS (ĐẶT HÀNG) ====================

  Future<List<OrderModel>> getOrdersByUserId(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders?userId=$userId&sortBy=createdAt&order=desc'));
      if (response.statusCode == 200) {
        List<dynamic> body = _decodeBody(response); // SỬA Ở ĐÂY
        return body.map((e) => OrderModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<OrderModel?> createOrder(OrderModel order) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(order.toJson()),
      );
      if (response.statusCode == 201) {
        // Hàm POST trả về có UTF-8 nên không cần decode thủ công
        return OrderModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'status': newStatus}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== 4. ADMIN FUNCTIONS ====================

  Future<List<OrderModel>> getAllOrders({String? status}) async {
    try {
      String url = '$baseUrl/orders?sortBy=createdAt&order=desc';
      if (status != null && status != 'All') {
        url += '&status=$status';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> body = _decodeBody(response); // SỬA Ở ĐÂY
        return body.map((e) => OrderModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addFood(FoodModel food) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/foods'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(food.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateFood(FoodModel food) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/foods/${food.id}'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(food.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFood(String foodId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/foods/$foodId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$id'));
      if (response.statusCode == 200) {
        // Chỗ này chỉ trả về 1 object, không phải list, nên decode khác
        var decodedBody = utf8.decode(response.bodyBytes);
        return UserModel.fromJson(jsonDecode(decodedBody));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
