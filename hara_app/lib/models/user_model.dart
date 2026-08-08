class UserModel {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String address;
  final String? area;
  final String userType;
  final String? photo;
  final String? storeName;
  final String? storeDescription;
  final double? deliveryFee;
  final List<String>? deliveryAreas;
  final String? vehicleType;
  final double rating;
  final int ratingCount;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    this.email = '',
    required this.name,
    required this.phone,
    required this.address,
    this.area,
    required this.userType,
    this.photo,
    this.storeName,
    this.storeDescription,
    this.deliveryFee,
    this.deliveryAreas,
    this.vehicleType,
    this.rating = 0,
    this.ratingCount = 0,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'name': name,
    'phone': phone,
    'address': address,
    'area': area,
    'userType': userType,
    'photo': photo,
    'storeName': storeName,
    'storeDescription': storeDescription,
    'deliveryFee': deliveryFee,
    'deliveryAreas': deliveryAreas,
    'vehicleType': vehicleType,
    'rating': rating,
    'ratingCount': ratingCount,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
    uid: uid,
    email: map['email'] ?? '',
    name: map['name'] ?? '',
    phone: map['phone'] ?? '',
    address: map['address'] ?? '',
    area: map['area'],
    userType: map['userType'] ?? 'buyer',
    photo: map['photo'],
    storeName: map['storeName'],
    storeDescription: map['storeDescription'],
    deliveryFee: (map['deliveryFee'] as num?)?.toDouble(),
    deliveryAreas: map['deliveryAreas'] != null ? List<String>.from(map['deliveryAreas']) : null,
    vehicleType: map['vehicleType'],
    rating: (map['rating'] as num?)?.toDouble() ?? 0,
    ratingCount: map['ratingCount'] ?? 0,
    isActive: map['isActive'] ?? true,
    createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => toMap();
}
