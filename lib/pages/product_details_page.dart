import 'package:agriplant/pages/cart_page.dart';
import 'package:agriplant/services/db_services.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import

import '../models/product.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final savedProductsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_products')
          .where('id', isEqualTo: widget.product.id)
          .get();

      setState(() {
        isBookmarked = savedProductsSnapshot.docs.isNotEmpty;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final savedProductsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_products');

      if (isBookmarked) {
        final savedProductSnapshot = await savedProductsRef
            .where('id', isEqualTo: widget.product.id)
            .get();

        for (var doc in savedProductSnapshot.docs) {
          await doc.reference.delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product removed from saved')),
        );
      } else {
        await savedProductsRef.add({
          'id': widget.product.id,
          'name': widget.product.name,
          'price': widget.product.price,
          'quantity': widget.product.quantity,
          'imageUrl': widget.product.image,
          'description': widget.product.description,
          'category': widget.product.category,
        });

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
    final product = {
      'name': widget.product.name,
      'price': widget.product.price,
      'quantity': quantity,
      'imageUrl': widget.product.image,
      'description': widget.product.description,
      'category': widget.product.category,
    };

    await DBService().insertProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added to cart')),
    );

    // Navigate to CartPage and add the product to the cart
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CartPage(),
        settings: RouteSettings(
          arguments: widget.product.copyWith(quantity: quantity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
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
          Container(
            height: 250,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: widget.product.image.startsWith('http')
                    ? NetworkImage(widget.product.image)
                    : AssetImage(widget.product.image) as ImageProvider,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Available in stock",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: "\$${widget.product.price}",
                        style: Theme.of(context).textTheme.titleLarge),
                    TextSpan(
                        text: " ${widget.product.category}",
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.star,
                size: 16,
                color: Colors.yellow.shade800,
              ),
              Text(
                "${widget.product.quantity} (192)",
              ),
              const Spacer(),
              SizedBox(
                height: 30,
                width: 30,
                child: IconButton.filledTonal(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      if (quantity > 1) quantity--;
                    });
                  },
                  iconSize: 18,
                  icon: const Icon(Icons.remove),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "$quantity",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              SizedBox(
                height: 30,
                width: 30,
                child: IconButton.filledTonal(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  iconSize: 18,
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text("Description",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: showMore
                      ? widget.product.description
                      : widget.product.description.length > 100
                          ? '${widget.product.description.substring(0, 100)}...'
                          : widget.product.description,
                ),
                TextSpan(
                  recognizer: readMoreGestureRecognizer,
                  text: showMore ? " Read less" : " Read more",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
              onPressed: _addToCart,
              icon: const Icon(IconlyLight.bag2),
              label: const Text("Add to cart"))
        ],
      ),
    );
  }
}
