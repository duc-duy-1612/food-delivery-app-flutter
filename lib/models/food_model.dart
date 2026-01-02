class FoodModel {
  String? id;
  String? categoryId;
  String? name;
  double? price;
  String? image;
  String? description;
  double? rating;
  bool isAvailable; // THÊM DÒNG NÀY

  FoodModel({
    this.id,
    this.categoryId,
    this.name,
    this.price,
    this.image,
    this.description,
    this.rating,
    this.isAvailable = true, // Mặc định là có sẵn
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'],
      categoryId: json['categoryId'],
      name: json['name'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: json['image'],
      description: json['description'],
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      // Đọc trạng thái từ API (nếu null thì coi như true)
      isAvailable: json['isAvailable'] == false ? false : true,
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
      'isAvailable': isAvailable, // Gửi lên API
    };

    if (id != null && id!.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}
