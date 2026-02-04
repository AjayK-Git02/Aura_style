class WardrobeItem {
  final String id;
  final String userId;
  final String? name;
  final String category;
  final String? color;
  final String? brand;
  final String imageUrl;
  final DateTime createdAt;

  WardrobeItem({
    required this.id,
    required this.userId,
    this.name,
    required this.category,
    this.color,
    this.brand,
    required this.imageUrl,
    required this.createdAt,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String?,
      category: json['category'] as String,
      color: json['color'] as String?,
      brand: json['brand'] as String?,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'color': color,
      'brand': brand,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
