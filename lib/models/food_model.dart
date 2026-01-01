class FoodModel {
  final String id;
  final String categoryId;
  final String name;
  final double price;
  final String image;
  final String description;
  final double rating;

  FoodModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.rating,
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? 'Unknown Food',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      'categoryId': categoryId,
      'rating': rating,
    };

    // Chỉ gửi ID nếu nó có giá trị thực sự (khi sửa món)
    // Khi thêm mới (id rỗng hoặc null), ta KHÔNG gửi id đi để MockAPI tự tạo
    if (id.isNotEmpty) {
      data['id'] = id;
    }

    return data;
  }
}