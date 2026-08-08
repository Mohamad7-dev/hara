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
    _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    notifyListeners();
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
