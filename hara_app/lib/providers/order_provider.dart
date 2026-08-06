import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';

class OrderProvider extends ChangeNotifier {
  static const String _key = 'orders';

  List<OrderModel> _orders = [];
  List<OrderModel> _availableOrders = [];
  List<OrderModel> _myDeliveryOrders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get availableOrders => _availableOrders;
  List<OrderModel> get myDeliveryOrders => _myDeliveryOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadLocal() async {
    _orders = LocalStore.instance
        .getList(_key)
        .map((m) => OrderModel.fromMap(m, m['id'] ?? ''))
        .toList();
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Delivery persons covering the buyer's area (name, phone, fee).
  Future<List<DeliveryOffer>> loadDeliveryOptions(String area) async {
    try {
      final res = await ApiClient.instance
          .get('api/delivery?area=${Uri.encodeQueryComponent(area)}');
      return (res as List)
          .map((m) => DeliveryOffer.fromMap(m as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return [];
    }
  }

  Future<void> loadBuyerOrders(String buyerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.instance.get('api/orders?scope=buyer');
      _orders = (res as List)
          .map((m) => OrderModel.fromMap(m as Map<String, dynamic>, m['id'] ?? ''))
          .toList();
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _save();
      _isLoading = false;
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    await _loadLocal();
    _orders = _orders.where((o) => o.buyerId == buyerId).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDeliveryOrders({
    required String uid,
    required List<String> areas,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiClient.instance.get('api/orders?scope=delivery');
      _availableOrders = (res['available'] as List)
          .map((m) => OrderModel.fromMap(m as Map<String, dynamic>, m['id'] ?? ''))
          .toList();
      _myDeliveryOrders = (res['mine'] as List)
          .map((m) => OrderModel.fromMap(m as Map<String, dynamic>, m['id'] ?? ''))
          .toList();
      _isLoading = false;
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    await _loadLocal();
    final available = <OrderModel>[];
    final mine = <OrderModel>[];
    for (final o in _orders) {
      final belongs = areas.any((a) => _matchesArea(o.buyerArea ?? '', a));
      if (o.status == 'pending') {
        if (belongs) available.add(o);
      } else if (o.deliveryPersonId == uid &&
          (o.status == 'accepted' ||
              o.status == 'delivering' ||
              o.status == 'delivered')) {
        mine.add(o);
      }
    }
    _availableOrders = available;
    _myDeliveryOrders = mine;
    _isLoading = false;
    notifyListeners();
  }

  bool _matchesArea(String buyerArea, String deliveryArea) {
    if (buyerArea.trim().isEmpty || deliveryArea.trim().isEmpty) return false;
    Set<String> tokens(String s) => s
        .replaceAll('·', '-')
        .split('-')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final b = tokens(buyerArea);
    final d = tokens(deliveryArea);
    return b.intersection(d).isNotEmpty;
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      final res = await ApiClient.instance.post('api/orders', order.toMap());
      final created =
          OrderModel.fromMap(res as Map<String, dynamic>, res['id'] ?? '');
      _orders.insert(0, created);
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    _orders.insert(0, order);
    await _save();
    notifyListeners();
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? deliveryPersonId,
    String? deliveryPersonName,
    String? paymentStatus,
    String? paymentRef,
  }) async {
    try {
      final res = await ApiClient.instance.patch('api/orders/$orderId', {
        'status': status,
        if (deliveryPersonId != null) 'deliveryPersonId': deliveryPersonId,
        if (deliveryPersonName != null) 'deliveryPersonName': deliveryPersonName,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        if (paymentRef != null) 'paymentRef': paymentRef,
      });
      _replace(res as Map<String, dynamic>);
      await _save();
      notifyListeners();
      return;
    } on ApiException {
      // offline fallback
    }
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    final map = Map<String, dynamic>.from(_orders[idx].toMap());
    map['status'] = status;
    if (deliveryPersonId != null) map['deliveryPersonId'] = deliveryPersonId;
    if (deliveryPersonName != null) map['deliveryPersonName'] = deliveryPersonName;
    if (paymentStatus != null) map['paymentStatus'] = paymentStatus;
    if (paymentStatus == 'paid') map['paidAt'] = DateTime.now().toIso8601String();
    if (paymentRef != null) map['paymentRef'] = paymentRef;
    if (status == 'delivered') {
      map['deliveredAt'] = DateTime.now().toIso8601String();
    }
    _orders[idx] = OrderModel.fromMap(map, orderId);
    await _save();
    notifyListeners();
  }

  /// Re-fetch the order to check whether an online payment went through.
  Future<OrderModel?> fetchOrder(String orderId) async {
    try {
      final res = await ApiClient.instance.get('api/orders?scope=buyer');
      for (final m in res) {
        final o = OrderModel.fromMap(m as Map<String, dynamic>, m['id'] ?? '');
        if (o.id == orderId) {
          _replace(o.toMap());
          await _save();
          notifyListeners();
          return o;
        }
      }
      return null;
    } on ApiException {
      return null;
    }
  }

  /// Marks an order as paid (driver cash collection or online confirmation).
  Future<void> markPaid(OrderModel order, {String? paymentRef}) async {
    await updateOrderStatus(
      order.id,
      order.status,
      paymentStatus: 'paid',
      paymentRef: paymentRef,
    );
  }

  /// Creates a myFatoorah payment session for an order.
  Future<Map<String, dynamic>?> createPaymentIntent(
    String orderId, {
    String method = 'card',
  }) async {
    try {
      final res = await ApiClient.instance
          .post('api/payments/intent', {'orderId': orderId, 'paymentMethod': method});
      return res as Map<String, dynamic>;
    } on ApiException {
      return null;
    }
  }

  /// Marks an order paid without a gateway (used when gateway is disabled).
  Future<bool> simulatePayment(String orderId) async {
    try {
      await ApiClient.instance.post('api/payments/simulate/$orderId', {});
      return true;
    } on ApiException {
      return false;
    }
  }

  void _replace(Map<String, dynamic> map) {
    final o = OrderModel.fromMap(map, map['id'] ?? '');
    final idx = _orders.indexWhere((x) => x.id == o.id);
    if (idx >= 0) {
      _orders[idx] = o;
    } else {
      _orders.insert(0, o);
    }
    final mi = _myDeliveryOrders.indexWhere((x) => x.id == o.id);
    if (mi >= 0) _myDeliveryOrders[mi] = o;
    final ai = _availableOrders.indexWhere((x) => x.id == o.id);
    if (ai >= 0) _availableOrders[ai] = o;
  }

  Future<void> _save() {
    return LocalStore.instance
        .saveCollection(_key, _orders.map((o) => o.toMap()).toList());
  }
}
