import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/local_store.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
  double get total => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  static const String _key = 'cart';

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);

  Future<void> load() async {
    _items.clear();
    final raw = LocalStore.instance.getList(_key);
    for (final m in raw) {
      final product = ProductModel.fromMap(
          m['product'] ?? {}, m['productId'] ?? '');
      _items.add(CartItem(product: product, quantity: (m['quantity'] as num?)?.toInt() ?? 1));
    }
    notifyListeners();
  }

  Future<void> addItem(ProductModel product) async {
    final existing = _items.indexWhere((item) => item.product.id == product.id);
    if (existing >= 0) {
      _items[existing].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    await _save();
    notifyListeners();
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.product.id == productId);
    await _save();
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      await _save();
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() {
    return LocalStore.instance.saveCollection(
      _key,
      _items
          .map((i) => {
                'productId': i.product.id,
                'quantity': i.quantity,
                'product': i.product.toMap(),
              })
          .toList(),
    );
  }
}
