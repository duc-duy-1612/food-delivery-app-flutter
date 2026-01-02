import 'package:flutter/material.dart';
import '../models/food_model.dart';

class CartItem {
  final FoodModel food;
  int quantity;
  String note;

  CartItem({
    required this.food,
    this.quantity = 1,
    this.note = "",
  });
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount {
    int total = 0;
    _items.forEach((key, item) {
      total += item.quantity;
    });
    return total;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += (cartItem.food.price ?? 0) * cartItem.quantity;
    });
    return total;
  }

  // 1. Cập nhật addItem: Thêm tham số note (mặc định là chuỗi rỗng)
  void addItem(FoodModel food, {String note = ""}) {
    final String key = food.id ?? 'unknown';

    if (!food.isAvailable) {
      print("Món ăn này đã hết hàng, không thể thêm vào giỏ.");
      return;
    }

    if (_items.containsKey(key)) {
      // Nếu đã có, chỉ cần tăng số lượng và cập nhật note nếu note mới không trống
      _items.update(
        key,
            (existing) => CartItem(
          food: existing.food,
          quantity: existing.quantity + 1,
          note: note.isNotEmpty ? note : existing.note,
        ),
      );
    } else {
      // Nếu chưa có, thêm mới vào Map
      _items.putIfAbsent(
        key,
            () => CartItem(food: food, note: note),
      );
    }
    notifyListeners();
  }

  // 2. Giảm số lượng
  void removeSingleItem(String foodId) {
    if (!_items.containsKey(foodId)) return;

    if (_items[foodId]!.quantity > 1) {
      _items.update(
        foodId,
            (existing) => CartItem(
          food: existing.food,
          quantity: existing.quantity - 1,
          note: existing.note, // Giữ nguyên note cũ khi giảm số lượng
        ),
      );
    } else {
      _items.remove(foodId);
    }
    notifyListeners();
  }

  void updateNote(String foodId, String newNote) {
    if (_items.containsKey(foodId)) {
      _items[foodId]!.note = newNote;
      notifyListeners();
    }
  }

  void deleteItem(String foodId) {
    _items.remove(foodId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}