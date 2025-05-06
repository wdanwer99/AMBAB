import 'package:agriplant/data/products.dart';
import 'package:agriplant/models/product.dart';
import 'package:agriplant/services/db_services.dart'; // Add this import
import 'package:agriplant/widgets/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cartItems = <Product>[];
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final products = await DBService().getProducts();
    final productList = products.map((product) {
      return Product(
        id: product['id'] ??
            UniqueKey().toString(), // Ensure the ID is not null
        name: product['name'] ?? '',
        price: product['price'] ?? 0.0,
        quantity: product['quantity'] ?? 1,
        image: product['imageUrl'] ?? '',
        description: product['description'] ?? '',
        category: product['category'] ?? '',
      );
    }).toList();

    setState(() {
      cartItems.addAll(productList);
      _calculateTotal();
    });

    // Check if a product was passed as an argument
    final Product? product =
        ModalRoute.of(context)?.settings.arguments as Product?;
    if (product != null) {
      if (!cartItems.any((item) => item.id == product.id)) {
        _addItemToCart(product);
      }
    }
  }

  void _calculateTotal() {
    total = cartItems.isNotEmpty
        ? cartItems
            .map((cartItem) => (cartItem.price) * (cartItem.quantity ?? 1))
            .reduce((value, element) => value + element)
        : 0.0;
    setState(() {});
  }

  void _updateItemQuantity(Product product, int quantity) {
    setState(() {
      final index = cartItems.indexOf(product);
      if (index != -1) {
        cartItems[index] = product.copyWith(quantity: quantity);
        _calculateTotal();
      }
    });
  }

  void _addItemToCart(Product product) async {
    setState(() {
      final index = cartItems.indexWhere((item) => item.name == product.name);
      if (index != -1) {
        cartItems[index] =
            cartItems[index].copyWith(quantity: product.quantity);
      } else {
        cartItems.add(product);
      }
      _calculateTotal();
    });
    await DBService().insertProduct({
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'quantity': product.quantity,
      'imageUrl': product.image,
      'description': product.description,
      'category': product.category,
    });
  }

  void _removeItemFromCart(Product product) {
    setState(() {
      cartItems.remove(product);
      _calculateTotal();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...List.generate(
              cartItems.length,
              (index) {
                final cartItem = cartItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: CartItem(
                    cartItem: cartItem,
                    onQuantityChanged: (quantity) {
                      _updateItemQuantity(cartItem, quantity);
                    },
                    onDismissed: () {
                      _removeItemFromCart(cartItem);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total (${cartItems.length} items)"),
                Text(
                  "\$${total.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                )
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                label: const Text("Proceed to Checkout"),
                icon: const Icon(IconlyBold.arrowRight),
              ),
            )
          ],
        ),
      ),
    );
  }
}
