import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/food_model.dart';
import '../../providers/cart_provider.dart';

class FoodDetailScreen extends StatelessWidget {
  final FoodModel food;

  const FoodDetailScreen({super.key, required this.food});

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. App Bar với ảnh món ăn co giãn (SliverAppBar)
          SliverAppBar(
            expandedHeight: 300, // Chiều cao ảnh khi kéo xuống
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: food.id ?? "food_image", // Hiệu ứng chuyển cảnh
                child: CachedNetworkImage(
                  imageUrl: food.image ?? "",
                  fit: BoxFit.cover,
                  errorWidget: (ctx, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, size: 100, color: Colors.grey),
                  ),
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ),

          // 2. Nội dung chi tiết
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên món ăn và Giá
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            food.name ?? "Món ăn",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatCurrency(food.price ?? 0),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Đánh giá (Rating) và Tình trạng (CẬP NHẬT LOGIC HẾT HÀNG)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 5),
                        Text("${food.rating ?? 5.0} / 5.0", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const Spacer(),

                        // --- Hiển thị trạng thái dựa trên isAvailable ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            // Nếu có hàng -> Màu xanh, Hết hàng -> Màu đỏ
                            color: food.isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: food.isAvailable ? Colors.green : Colors.red),
                          ),
                          child: Text(
                              food.isAvailable ? "Còn hàng" : "Hết hàng",
                              style: TextStyle(
                                  color: food.isAvailable ? Colors.green : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold
                              )
                          ),
                        )
                        // ------------------------------------------------
                      ],
                    ),
                    const Divider(height: 30),

                    // Mô tả
                    const Text("Mô tả món ăn", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      (food.description != null && food.description!.isNotEmpty)
                          ? food.description!
                          : "Chưa có mô tả chi tiết cho món ăn này.",
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                    ),

                    const SizedBox(height: 100), // Khoảng trống để không bị nút che mất
                  ],
                ),
              )
            ]),
          ),
        ],
      ),

      // Nút "Thêm vào giỏ" ghim ở dưới đáy (CẬP NHẬT LOGIC HẾT HÀNG)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            // Icon thay đổi nếu hết hàng
            icon: Icon(
                food.isAvailable ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
                color: Colors.white
            ),
            // Text thay đổi nếu hết hàng
            label: Text(
                food.isAvailable ? "THÊM VÀO GIỎ HÀNG" : "TẠM HẾT HÀNG",
                style: const TextStyle(color: Colors.white, fontSize: 18)
            ),
            style: ElevatedButton.styleFrom(
              // Màu nút thay đổi: Cam (có hàng) vs Xám (hết hàng)
              backgroundColor: food.isAvailable ? Colors.orange : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: food.isAvailable
                ? () {
              // Logic khi CÒN hàng
              Provider.of<CartProvider>(context, listen: false).addItem(food);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Đã thêm ${food.name} vào giỏ!"),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            }
                : () {
              // Logic khi HẾT hàng (Bấm vào sẽ báo lỗi)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Món này hiện đang tạm ngưng phục vụ!"),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
