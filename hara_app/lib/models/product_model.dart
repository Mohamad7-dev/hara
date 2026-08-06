class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String category;
  final List<String> images;
  final int stock;
  final String? unit;
  final bool isAvailable;
  final bool featured;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'شيكل',
    required this.category,
    required this.images,
    this.stock = 1,
    this.unit,
    this.isAvailable = true,
    this.featured = false,
    this.rating = 0,
    this.ratingCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'title': title,
    'description': description,
    'price': price,
    'currency': currency,
    'category': category,
    'images': images,
    'stock': stock,
    'unit': unit,
    'isAvailable': isAvailable,
    'featured': featured,
    'rating': rating,
    'ratingCount': ratingCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) => ProductModel(
    id: id,
    sellerId: map['sellerId'] ?? '',
    sellerName: map['sellerName'] ?? '',
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0,
    currency: map['currency'] ?? 'شيكل',
    category: map['category'] ?? '',
    images: map['images'] != null ? List<String>.from(map['images']) : [],
    stock: map['stock'] ?? 0,
    unit: map['unit'],
    isAvailable: map['isAvailable'] ?? true,
    featured: map['featured'] ?? false,
    rating: (map['rating'] as num?)?.toDouble() ?? 0,
    ratingCount: map['ratingCount'] ?? 0,
    createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
  );
}
