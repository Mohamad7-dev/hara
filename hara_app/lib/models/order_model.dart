class OrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerAddress;
  final String? buyerArea;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final double? deliveryFee;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentRef;
  final DateTime? paidAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    this.buyerArea,
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.deliveryFee,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.paymentRef,
    this.paidAt,
    this.notes,
    DateTime? createdAt,
    this.deliveredAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'buyerId': buyerId,
    'buyerName': buyerName,
    'buyerPhone': buyerPhone,
    'buyerAddress': buyerAddress,
    'buyerArea': buyerArea,
    'deliveryPersonId': deliveryPersonId,
    'deliveryPersonName': deliveryPersonName,
    'deliveryFee': deliveryFee,
    'status': status,
    'items': items.map((e) => e.toMap()).toList(),
    'subtotal': subtotal,
    'total': total,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'paymentRef': paymentRef,
    'paidAt': paidAt?.toIso8601String(),
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
  };

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) => OrderModel(
    id: id,
    buyerId: map['buyerId'] ?? '',
    buyerName: map['buyerName'] ?? '',
    buyerPhone: map['buyerPhone'] ?? '',
    buyerAddress: map['buyerAddress'] ?? '',
    buyerArea: map['buyerArea'],
    deliveryPersonId: map['deliveryPersonId'],
    deliveryPersonName: map['deliveryPersonName'],
    deliveryFee: (map['deliveryFee'] as num?)?.toDouble(),
    status: map['status'] ?? 'pending',
    items: (map['items'] as List?)?.map((e) => OrderItem.fromMap(e)).toList() ?? [],
    subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
    total: (map['total'] as num?)?.toDouble() ?? 0,
    paymentMethod: map['paymentMethod'] ?? 'cash',
    paymentStatus: map['paymentStatus'] ?? 'pending',
    paymentRef: map['paymentRef'],
    paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
    notes: map['notes'],
    createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    deliveredAt: map['deliveredAt'] != null ? DateTime.parse(map['deliveredAt']) : null,
  );
}

class OrderItem {
  final String productId;
  final String productTitle;
  final double price;
  final int quantity;
  final String? imageUrl;
  OrderItem({
    required this.productId,
    required this.productTitle,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productTitle': productTitle,
    'price': price,
    'quantity': quantity,
    'imageUrl': imageUrl,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] ?? '',
    productTitle: map['productTitle'] ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0,
    quantity: map['quantity'] ?? 1,
    imageUrl: map['imageUrl'],
  );

  double get total => price * quantity;
}

class DeliveryOffer {
  final String uid;
  final String name;
  final String phone;
  final double fee;
  final List<String> areas;
  final String? vehicle;
  final double rating;
  final int ratingCount;

  DeliveryOffer({
    required this.uid,
    required this.name,
    required this.phone,
    required this.fee,
    this.areas = const [],
    this.vehicle,
    this.rating = 0,
    this.ratingCount = 0,
  });

  factory DeliveryOffer.fromMap(Map<String, dynamic> map) => DeliveryOffer(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    fee: (map['deliveryFee'] as num?)?.toDouble() ?? 5,
    areas: map['deliveryAreas'] != null
        ? List<String>.from(map['deliveryAreas'])
        : const [],
    vehicle: map['vehicleType'],
    rating: (map['rating'] as num?)?.toDouble() ?? 0,
    ratingCount: map['ratingCount'] ?? 0,
  );
}
