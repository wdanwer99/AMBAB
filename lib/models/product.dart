class Product {
  final String name;
  final double price;
  final String image;
  final String description;
  final String category;
  // final double rating;
  final int quantity;

  Product({
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    // required this.unit,
    // required this.rating,
    this.quantity = 1,
    required this.category,
    required id,
  });

  // Factory constructor to create a Product from a JSON map
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      description: json['description'] as String,
      // unit: json['unit'] as String,
      // rating: (json['rating'] as num).toDouble(),
      quantity: json['quantity'] != null ? json['quantity'] as int : 1,
      category: json['category'] as String, id: null,
    );
  }

  get id => null;

  // Method to convert a Product object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'image': image,
      'description': description,
      // 'unit': unit,
      // 'rating': rating,
      'quantity': quantity,
    };
  }

  Product copyWith({
    String? name,
    double? price,
    String? image,
    String? description,
    String? unit,
    double? rating,
    int? quantity,
  }) {
    return Product(
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      description: description ?? this.description,
      // unit: unit ?? this.unit,
      // rating: rating ?? this.rating,
      quantity: quantity ?? this.quantity, category: category, id: null,
    );
  }
}
