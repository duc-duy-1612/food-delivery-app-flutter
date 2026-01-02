import 'dart:convert';

class OrderModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userPhone; // THÊM
  final String? userEmail; // THÊM
  final double totalPrice;
  final String status;
  final String address;
  final String createdAt;
  List<dynamic>? items; // Trong App nó là List, nhưng lên API nó sẽ biến thành String

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone, // THÊM
    required this.userEmail, // THÊM
    required this.totalPrice,
    required this.status,
    required this.address,
    required this.createdAt,
    required this.items,
  });

  // 1. Hàm chuyển dữ liệu từ API (JSON) về Object Dart
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['userId'],
      userName: (json['userName'] != null && json['userName'].toString().isNotEmpty)
          ? json['userName'].toString()
          : "Khách lẻ",
      userPhone: json['userPhone']?.toString() ?? "",
      userEmail: json['userEmail']?.toString() ?? "",
      totalPrice: double.tryParse(json['totalPrice'].toString()) ?? 0.0,
      status: json['status'],
      address: json['address'],
      createdAt: json['createdAt'],

      // QUAN TRỌNG: Giải mã chuỗi JSON từ trường 'items' thành List
      items: json['items'] != null
          ? jsonDecode(json['items']) as List<dynamic>
          : [],
    );
  }

  // 2. Hàm đóng gói Object Dart thành JSON để gửi lên API
  Map<String, dynamic> toJson() {
    return {
      // Không gửi ID vì MockAPI tự tạo
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'totalPrice': totalPrice,
      'status': status,
      'address': address,
      'createdAt': createdAt,

      // QUAN TRỌNG: Mã hóa List thành chuỗi JSON String để lưu vào MockAPI
      'items': jsonEncode(items),
    };
  }
}
