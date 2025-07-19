import 'package:supabase_flutter/supabase_flutter.dart';

class Product {
  final String? id;
  final String name;
  final double price;
  final String image;
  final String description;
  final String category;
  final int quantity;
  final String vendorId;
  final String vendorName;
  final String? vendorStoreName;
  final bool isAvailable;
  final DateTime createdAt;
  final double rating;
  final int totalSold;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    this.quantity = 1,
    required this.category,
    required this.vendorId,
    required this.vendorName,
    this.vendorStoreName,
    this.isAvailable = true,
    required this.createdAt,
    this.rating = 0.0,
    this.totalSold = 0,
  });

  // Factory constructor to create a Product from a JSON map
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      description: json['description'] as String,
      quantity: json['quantity'] != null ? json['quantity'] as int : 1,
      category: json['category'] as String,
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String,
      vendorStoreName: json['vendor_store_name'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: _parseDateTime(json['created_at']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalSold: json['total_sold'] as int? ?? 0,
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

  // Method to convert a Product object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      'quantity': quantity,
      'category': category,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'vendor_store_name': vendorStoreName,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'rating': rating,
      'total_sold': totalSold,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? image,
    String? description,
    String? category,
    int? quantity,
    String? vendorId,
    String? vendorName,
    String? vendorStoreName,
    bool? isAvailable,
    DateTime? createdAt,
    double? rating,
    int? totalSold,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorStoreName: vendorStoreName ?? this.vendorStoreName,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      totalSold: totalSold ?? this.totalSold,
    );
  }
}
