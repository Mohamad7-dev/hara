import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class ProductProvider extends ChangeNotifier {
  static const String _key = 'products';

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  List<ProductModel> get products {
    var list = _products;
    if (_selectedCategory != 'الكل') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    final q = _searchQuery.trim();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q.toLowerCase()) ||
              p.description.toLowerCase().contains(q.toLowerCase()))
          .toList();
    }
    return list;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.instance.get('api/products');
      final list = (res as List)
          .map((m) => ProductModel.fromMap(m as Map<String, dynamic>, m['id'] ?? ''))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _products = list;
      await _save();
      _isLoading = false;
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    _products = LocalStore.instance
        .getList(_key)
        .map((m) => ProductModel.fromMap(m, m['id'] ?? ''))
        .toList();
    if (_products.isEmpty) {
      _seedDemoProducts();
      await _save();
    }
    _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    notifyListeners();
  }

  void _seedDemoProducts() {
    final now = DateTime.now();
    _products = [
      ProductModel(
        id: 'p1',
        sellerId: 'user1',
        sellerName: 'محمد أبو أحمد',
        title: 'زيت زيتون بلدي',
        description: 'زيت زيتون عذراء طبيعي 100% معصور على البارد من مزرعة العائلة.',
        price: 35,
        category: 'طعام',
        images: [],
        stock: 50,
        rating: 4.8,
        ratingCount: 23,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ProductModel(
        id: 'p2',
        sellerId: 'user1',
        sellerName: 'محمد أبو أحمد',
        title: 'تمر مجهول فاخر',
        description: 'تمر مجهول عضوي فاخر، وزن 1 كجم، منتج طبيعي بدون مواد حافظة.',
        price: 28,
        category: 'طعام',
        images: [],
        stock: 30,
        rating: 4.6,
        ratingCount: 15,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ProductModel(
        id: 'p3',
        sellerId: 'user1',
        sellerName: 'محمد أبو أحمد',
        title: 'عصير طبيعي',
        description: 'عصير برتقال طبيعي طازج بدون سكر مضاف، معصور يومياً.',
        price: 8,
        category: 'طعام',
        images: [],
        stock: 100,
        rating: 4.5,
        ratingCount: 8,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ProductModel(
        id: 'p4',
        sellerId: 'user2',
        sellerName: 'سامي عوض',
        title: 'شنطة يدوية',
        description: 'شنطة يد مصنوعة يدوياً من القماش الفلسطيني المطرّز، تصميم عصري ومتين.',
        price: 45,
        category: 'هدايا',
        images: [],
        stock: 10,
        rating: 5.0,
        ratingCount: 5,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ProductModel(
        id: 'p5',
        sellerId: 'user2',
        sellerName: 'سامي عوض',
        title: 'لابتوب مستعمل',
        description: 'لابتوب بحالة ممتازة، معالج i5، رام 8 جيجا، شاشة 15 بوصة.',
        price: 850,
        category: 'لابتوبات',
        images: [],
        stock: 1,
        rating: 4.3,
        ratingCount: 11,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      ProductModel(
        id: 'p6',
        sellerId: 'user1',
        sellerName: 'محمد أبو أحمد',
        title: 'هاتف سامسونج',
        description: 'هاتف سامسونج شبه جديد، بطارية ممتازة، مع الشاحن والعلبة.',
        price: 420,
        category: 'هواتف',
        images: [],
        stock: 1,
        rating: 4.7,
        ratingCount: 18,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      final res = await ApiClient.instance.post('api/products', {
        'title': product.title,
        'description': product.description,
        'price': product.price,
        'currency': product.currency,
        'category': product.category,
        'images': product.images,
        'stock': product.stock,
        'featured': product.featured,
      });
      final added = ProductModel.fromMap(res as Map<String, dynamic>, res['id'] ?? '');
      _products.insert(0, added);
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    final added = ProductModel(
      id: product.id.isEmpty ? 'p${DateTime.now().millisecondsSinceEpoch}' : product.id,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      title: product.title,
      description: product.description,
      price: product.price,
      category: product.category,
      images: product.images,
      stock: product.stock,
      rating: product.rating,
      ratingCount: product.ratingCount,
      featured: product.featured,
    );
    _products.insert(0, added);
    await _save();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  ProductModel? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> decrementStock(String productId, int quantity) async {
    try {
      final res = await ApiClient.instance
          .post('api/products/$productId/stock?quantity=$quantity', {});
      _replace(res as Map<String, dynamic>);
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0) return;
    final p = _products[idx];
    final newStock = (p.stock - quantity) < 0 ? 0 : p.stock - quantity;
    _products[idx] = ProductModel(
      id: p.id,
      sellerId: p.sellerId,
      sellerName: p.sellerName,
      title: p.title,
      description: p.description,
      price: p.price,
      currency: p.currency,
      category: p.category,
      images: p.images,
      stock: newStock,
      unit: p.unit,
      isAvailable: newStock > 0 ? p.isAvailable : false,
      featured: p.featured,
      rating: p.rating,
      ratingCount: p.ratingCount,
      createdAt: p.createdAt,
    );
    await _save();
    notifyListeners();
  }

  Future<void> addReview(String productId, int rating) async {
    try {
      final res = await ApiClient.instance
          .post('api/products/$productId/review?rating=$rating', {});
      _replace(res as Map<String, dynamic>);
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx < 0 || rating < 1 || rating > 5) return;
    final p = _products[idx];
    final newCount = p.ratingCount + 1;
    final newRating = (p.rating * p.ratingCount + rating) / newCount;
    _products[idx] = ProductModel(
      id: p.id,
      sellerId: p.sellerId,
      sellerName: p.sellerName,
      title: p.title,
      description: p.description,
      price: p.price,
      currency: p.currency,
      category: p.category,
      images: p.images,
      stock: p.stock,
      unit: p.unit,
      isAvailable: p.isAvailable,
      featured: p.featured,
      rating: double.parse(newRating.toStringAsFixed(1)),
      ratingCount: newCount,
      createdAt: p.createdAt,
    );
    await _save();
    notifyListeners();
  }

  void _replace(Map<String, dynamic> map) {
    final p = ProductModel.fromMap(map, map['id'] ?? '');
    final idx = _products.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      _products[idx] = p;
    } else {
      _products.insert(0, p);
    }
  }

  Future<void> _save() {
    return LocalStore.instance
        .saveCollection(_key, _products.map((p) => p.toMap()).toList());
  }
}
