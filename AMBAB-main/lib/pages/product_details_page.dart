import 'package:agriplant/pages/cart_page.dart';
import 'package:agriplant/services/db_services.dart';
import 'package:agriplant/services/supabase_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../widgets/product_image.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late TapGestureRecognizer readMoreGestureRecognizer;
  bool showMore = false;
  int quantity = 1;
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    readMoreGestureRecognizer = TapGestureRecognizer()
      ..onTap = () {
        setState(() {
          showMore = !showMore;
        });
      };
    _checkIfBookmarked();
  }

  @override
  void dispose() {
    super.dispose();
    readMoreGestureRecognizer.dispose();
  }

  Future<void> _checkIfBookmarked() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      final savedProducts = await SupabaseService.getSavedProducts(user.id);
      setState(() {
        isBookmarked = savedProducts.any((product) => product['product_id'] == widget.product.id);
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      if (isBookmarked) {
        await SupabaseService.deleteSavedProduct(
          userId: user.id,
          productId: widget.product.id!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product removed from saved')),
        );
      } else {
        await SupabaseService.saveProduct(
          userId: user.id,
          productId: widget.product.id!,
          productData: {
            'id': widget.product.id,
            'name': widget.product.name,
            'price': widget.product.price,
            'quantity': widget.product.quantity,
            'image': widget.product.image,
            'description': widget.product.description,
            'category': widget.product.category,
            'vendor_name': widget.product.vendorName,
            'vendor_store_name': widget.product.vendorStoreName,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved')),
        );
      }

      setState(() {
        isBookmarked = !isBookmarked;
      });
    }
  }

  Future<void> _addToCart() async {
    try {
      // Check if user is authenticated
      final user = SupabaseService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to add items to cart'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if product is available
      if (!widget.product.isAvailable || widget.product.quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product is out of stock'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if quantity is valid
      if (quantity > widget.product.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only ${widget.product.quantity} items available in stock'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Note: Database insert will be handled by CartPage when it receives the product argument

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} added to cart (${quantity}x)'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CartPage(),
                ),
              );
            },
          ),
        ),
      );

      // Navigate to CartPage
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CartPage(),
          settings: RouteSettings(
            arguments: widget.product.copyWith(quantity: quantity),
          ),
        ),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          IconButton(
            onPressed: _toggleBookmark,
            icon: Icon(
              isBookmarked ? IconlyBold.bookmark : IconlyLight.bookmark,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Product Image
          Container(
            height: 250,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ProductImage(
              imageUrl: widget.product.image,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          
          // Product Name and Price
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Text(
                "\$${widget.product.price.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      widget.product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Vendor Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          Icons.store,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.vendorStoreName ?? widget.product.vendorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Seller',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.product.vendorStoreName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Verified Store',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stock Information
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.product.isAvailable ? "Available in stock" : "Out of stock",
                style: TextStyle(
                  color: widget.product.isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Stock: ${widget.product.quantity}",
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quantity Selector
          if (widget.product.isAvailable) ...[
            Row(
              children: [
                const Text(
                  "Quantity: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: quantity > 1 ? () {
                          setState(() {
                            quantity--;
                          });
                        } : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "$quantity",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: quantity < widget.product.quantity ? () {
                          setState(() {
                            quantity++;
                          });
                        } : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          
          // Description
          const Text(
            "Description",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: showMore
                      ? widget.product.description
                      : widget.product.description.length > 150
                          ? '${widget.product.description.substring(0, 150)}...'
                          : widget.product.description,
                ),
                TextSpan(
                  recognizer: readMoreGestureRecognizer,
                  text: showMore ? " Read less" : " Read more",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Add to Cart Button
          if (widget.product.isAvailable)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(IconlyLight.bag2),
                label: const Text(
                  "Add to Cart",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Out of Stock",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
