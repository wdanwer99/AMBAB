import 'package:supabase_flutter/supabase_flutter.dart';

class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String? storeName;
  final String? storeDescription;
  final String? storeImage;
  final bool isVerified;
  final DateTime createdAt;
  final double rating;
  final int totalProducts;
  final int totalSales;
  final bool? isDisabled;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    this.storeName,
    this.storeDescription,
    this.storeImage,
    this.isVerified = false,
    required this.createdAt,
    this.rating = 0.0,
    this.totalProducts = 0,
    this.totalSales = 0,
    this.isDisabled,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'].toString(),
      location: json['location'] as String,
      storeName: json['store_name'] as String?,
      storeDescription: json['store_description'] as String?,
      storeImage: json['store_image'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalProducts: json['total_products'] as int? ?? 0,
      totalSales: json['total_sales'] as int? ?? 0,
      isDisabled: json['is_disabled'] as bool?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'store_name': storeName,
      'store_description': storeDescription,
      'store_image': storeImage,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'rating': rating,
      'total_products': totalProducts,
      'total_sales': totalSales,
      'is_disabled': isDisabled,
    };
  }

  Vendor copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? location,
    String? storeName,
    String? storeDescription,
    String? storeImage,
    bool? isVerified,
    DateTime? createdAt,
    double? rating,
    int? totalProducts,
    int? totalSales,
    bool? isDisabled,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      storeImage: storeImage ?? this.storeImage,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      totalProducts: totalProducts ?? this.totalProducts,
      totalSales: totalSales ?? this.totalSales,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
} 