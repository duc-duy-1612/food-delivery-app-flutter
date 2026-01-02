import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Để format tiền tệ
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/category_model.dart';
import '../../models/food_model.dart';
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../auth/login_screen.dart';

import '../cart/cart_screen.dart';
import '../history/history_screen.dart';
import '../home/profile_screen.dart';
import '../home/food_detail_screen.dart'; // Import màn hình chi tiết món ăn

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<CategoryModel> _categories = [];
  List<FoodModel> _foods = [];
  bool _isLoading = true;
  String _selectedCategoryId = "ALL";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tải dữ liệu từ API
  Future<void> _loadData() async {
    try {
      final categoriesData = await _apiService.getCategories();
      final foodsData = await _apiService.getFoods();

      setState(() {
        _categories = categoriesData;
        _foods = foodsData;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi tải dữ liệu: $e");
      setState(() => _isLoading = false);
    }
  }

  String formatCurrency(double price) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return format.format(price);
  }

  // Hàm lọc món ăn theo danh mục đang chọn
  List<FoodModel> get _filteredFoods {
    if (_selectedCategoryId == "ALL") {
      return _foods;
    }
    return _foods.where((food) => food.categoryId == _selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy user từ Provider để hiển thị tên "Xin chào..."
    final user = Provider.of<UserProvider>(context).user;

    // Lấy số lượng món trong giỏ hàng để hiện lên icon
    final cartItemCount = Provider.of<CartProvider>(context).itemCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Cơm Tấm Kim ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Hi, ${user?.name ?? 'Khách'}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        actions: [
          // Nút Lịch sử đơn hàng
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          // Nút Giỏ hàng
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),

          // Nút Hồ sơ cá nhân
          IconButton(icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),

          // Nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 1. Danh sách Category (Chạy ngang)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1, // +1 cho nút "Tất cả"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Nút "Tất cả"
                  return _buildCategoryItem(id: "ALL", name: "Tất cả");
                }
                final category = _categories[index - 1];
                return _buildCategoryItem(id: category.id!, name: category.name!);
              },
            ),
          ),

          const Divider(),

          // 2. Danh sách Món ăn (Lưới Grid)
          Expanded(
            child: _filteredFoods.isEmpty
                ? const Center(child: Text("Không có món ăn nào!"))
                : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cột
                childAspectRatio: 0.75, // Tỷ lệ chiều rộng/cao
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _filteredFoods.length,
              itemBuilder: (context, index) {
                final food = _filteredFoods[index];
                return _buildFoodCard(food);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị 1 item category
  Widget _buildCategoryItem({required String id, required String name}) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryId = id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Widget hiển thị 1 thẻ món ăn
  Widget _buildFoodCard(FoodModel food) {
    // Bọc Card trong GestureDetector để xử lý sự kiện bấm vào xem chi tiết
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FoodDetailScreen(food: food)),
        );
      },
      child: Hero(
        tag: food.id!, // Hero animation tag
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh món ăn
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: food.image ?? "",
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              // Thông tin tên, giá
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name ?? "Món ăn",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      formatCurrency(food.price ?? 0),
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    // Nút thêm vào giỏ
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          // Gọi Provider để thêm vào giỏ
                          Provider.of<CartProvider>(context, listen: false).addItem(food);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Đã thêm ${food.name} vào giỏ!"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Text("Thêm", style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
