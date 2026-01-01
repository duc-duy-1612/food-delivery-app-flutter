import 'package:flutter/material.dart';
import '../../models/food_model.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';

class AdminFoodEditScreen extends StatefulWidget {
  final FoodModel? food; // Nếu null là Thêm mới, nếu có dữ liệu là Sửa

  const AdminFoodEditScreen({super.key, this.food});

  @override
  State<AdminFoodEditScreen> createState() => _AdminFoodEditScreenState();
}

class _AdminFoodEditScreenState extends State<AdminFoodEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers cho các ô nhập
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descController;

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo giá trị ban đầu (nếu là sửa thì điền sẵn)
    _nameController = TextEditingController(text: widget.food?.name ?? "");
    _priceController = TextEditingController(text: widget.food?.price?.toString() ?? "");
    _imageController = TextEditingController(text: widget.food?.image ?? "");
    _descController = TextEditingController(text: widget.food?.description ?? "");
    _selectedCategoryId = widget.food?.categoryId;

    _loadCategories();
  }

  // Tải danh mục để chọn khi thêm/sửa món
  Future<void> _loadCategories() async {
    final cats = await _apiService.getCategories();
    setState(() {
      _categories = cats;
      // Nếu là thêm mới và chưa chọn danh mục, mặc định chọn cái đầu tiên
      if (_selectedCategoryId == null && cats.isNotEmpty) {
        _selectedCategoryId = cats.first.id;
      }
    });
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng chọn danh mục")));
      return;
    }

    setState(() => _isLoading = true);

    // Tạo object FoodModel từ dữ liệu nhập
    FoodModel newFood = FoodModel(
      id: widget.food?.id ?? "",
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      image: _imageController.text,
      description: _descController.text,
      categoryId: _selectedCategoryId ?? "",
      rating: widget.food != null ? widget.food!.rating : 5.0,    );

    bool success;
    if (widget.food == null) {
      // THÊM MỚI
      success = await _apiService.addFood(newFood);
    } else {
      // CẬP NHẬT
      success = await _apiService.updateFood(newFood);
    }

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lưu thành công!")));
      Navigator.pop(context, true); // Trả về true để màn hình trước tải lại danh sách
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi lưu!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.food != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Sửa Món Ăn" : "Thêm Món Mới")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Nhập Tên
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Tên món ăn", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 15),

              // Nhập Giá
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Giá tiền (VNĐ)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Nhập giá tiền" : null,
              ),
              const SizedBox(height: 15),

              // Chọn Danh mục
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: "Danh mục", border: OutlineInputBorder()),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name ?? "Không tên"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 15),

              // Nhập Link ảnh
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: "Link hình ảnh (URL)", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Cần có hình ảnh" : null,
              ),
              const SizedBox(height: 10),
              // Preview ảnh nếu có link
              if (_imageController.text.isNotEmpty)
                Image.network(
                  _imageController.text,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => const Text("Link ảnh lỗi hoặc chưa nhập"),
                ),

              const SizedBox(height: 15),

              // Nhập Mô tả
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Mô tả chi tiết", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Nút Lưu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("LƯU MÓN ĂN", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                  onPressed: _saveFood,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
