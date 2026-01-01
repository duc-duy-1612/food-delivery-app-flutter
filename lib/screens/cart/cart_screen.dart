import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../history/order_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _addressController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _addressController.text = user.address ?? "";
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String formatCurrency(double price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(price);
  }

  void _placeOrder(CartProvider cart) async {
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Giỏ hàng đang trống!")));
      return;
    }
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập địa chỉ giao hàng")));
      return;
    }

    setState(() => _isLoading = true);

    final user = Provider.of<UserProvider>(context, listen: false).user;

    List<Map<String, dynamic>> orderItems = [];
    cart.items.forEach((key, cartItem) {
      orderItems.add({
        'id': cartItem.food.id,
        'name': cartItem.food.name,
        'price': cartItem.food.price,
        'quantity': cartItem.quantity,
        'image': cartItem.food.image,
        'note': cartItem.note,
      });
    });

    OrderModel newOrder = OrderModel(
      id: "",
      userId: user?.id ?? "unknown_user",
      totalPrice: cart.totalAmount,
      status: "Placed",
      address: _addressController.text,
      createdAt: DateTime.now().toIso8601String(),
      items: orderItems,
    );

    final createdOrder = await _apiService.createOrder(newOrder);

    setState(() => _isLoading = false);

    if (createdOrder != null) {
      cart.clear();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(order: createdOrder),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đặt hàng thành công!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi đặt hàng. Vui lòng thử lại!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ Hàng")),
      body: cartItems.isEmpty
          ? const Center(child: Text("Giỏ hàng đang trống", style: TextStyle(fontSize: 18)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final foodId = item.food.id ?? "";

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.food.image ?? "",
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, __) => const Icon(Icons.fastfood),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.food.name ?? "",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(formatCurrency(item.food.price ?? 0),
                                      style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => cart.removeSingleItem(foodId),
                                ),
                                Text("${item.quantity}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                  onPressed: () => cart.addItem(item.food),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              onPressed: () => cart.deleteItem(foodId),
                            )
                          ],
                        ),
                        const Divider(),
                        // PHẦN GHI CHÚ
                        TextField(
                          // Quan trọng: Sử dụng onChanged để cập nhật note vào Provider ngay lập tức
                          onChanged: (value) => cart.updateNote(foodId, value),
                          decoration: const InputDecoration(
                            hintText: "Ghi chú (Vd: Không hành...)",
                            isDense: true,
                            prefixIcon: Icon(Icons.edit_note, size: 20),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 13),
                          // Để không bị reset text khi ListView render lại
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                              text: item.note,
                              selection: TextSelection.collapsed(offset: item.note.length),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildCheckoutSection(cart),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 7, offset: const Offset(0, -3))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: "Địa chỉ giao hàng",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng tiền:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(formatCurrency(cart.totalAmount),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: _isLoading ? null : () => _placeOrder(cart),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ĐẶT HÀNG NGAY", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}