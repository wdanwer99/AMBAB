
import 'package:agriplant/models/product.dart';
import 'package:agriplant/services/db_services.dart';
import 'package:agriplant/services/supabase_service.dart';
import 'package:agriplant/widgets/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'checkout_page.dart';
import 'package:agriplant/pages/explore_page.dart';
import 'package:agriplant/pages/home_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final cartItems = <Product>[];
  double total = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      setState(() {
        isLoading = true;
      });

      final products = await DBService().getProducts();
      final productList = products.map((product) {
        return Product(
          id: product['id']?.toString() ?? UniqueKey().toString(),
          name: product['name'] ?? '',
          price: (product['price'] ?? 0.0).toDouble(),
          quantity: product['quantity'] ?? 1,
          image: product['imageUrl'] ?? '',
          description: product['description'] ?? '',
          category: product['category'] ?? '',
          vendorId: product['vendor_id'] ?? 'local',
          vendorName: product['vendor_name'] ?? 'Local Store',
          vendorStoreName: product['vendor_store_name'],
          createdAt: DateTime.now(),
        );
      }).toList();

      setState(() {
        cartItems.clear();
        cartItems.addAll(productList);
        _calculateTotal();
        isLoading = false;
      });

      // Check if a product was passed as an argument
      final Product? product =
          ModalRoute.of(context)?.settings.arguments as Product?;
      if (product != null) {
        // Check if the product already exists in the current cart items
        final existingIndex = cartItems.indexWhere(
          (item) => item.name == product.name && 
                    item.vendorId == product.vendorId
        );
        
        if (existingIndex == -1) {
          // Product doesn't exist in cart, add it
          _addItemToCart(product);
        } else {
          // Product exists, update quantity
          final currentQuantity = cartItems[existingIndex].quantity ?? 1;
          final newQuantity = currentQuantity + product.quantity;
          _updateItemQuantity(cartItems[existingIndex], newQuantity);
        }
      }
    } catch (e) {
      print('Error loading cart items: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  void _updateItemQuantity(Product product, int quantity) async {
    try {
      setState(() {
        final index = cartItems.indexOf(product);
        if (index != -1) {
          cartItems[index] = product.copyWith(quantity: quantity);
          _calculateTotal();
        }
      });

      // Update in local database
      if (product.id != null) {
        final id = int.tryParse(product.id!) ?? 0;
        if (id > 0) {
          await DBService().updateProduct({
            'id': id,
            'quantity': quantity,
          }, {});
        }
      }
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating quantity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addItemToCart(Product product) async {
    try {
      setState(() {
        final index = cartItems.indexWhere((item) => item.id == product.id);
        if (index != -1) {
          cartItems[index] =
              cartItems[index].copyWith(quantity: product.quantity);
        } else {
          cartItems.add(product);
        }
        _calculateTotal();
      });

      await DBService().insertProduct({
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'imageUrl': product.image,
        'description': product.description,
        'category': product.category,
        'vendor_id': product.vendorId,
        'vendor_name': product.vendorName,
        'vendor_store_name': product.vendorStoreName,
        'user_id': SupabaseService.getCurrentUser()?.id,
        'added_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding item to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeItemFromCart(Product product) async {
    try {
      setState(() {
        cartItems.remove(product);
        _calculateTotal();
      });

      // Remove from local database
      if (product.id != null) {
        final id = int.tryParse(product.id!) ?? 0;
        if (id > 0) {
          await DBService().deleteProduct(id);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} removed from cart'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () => _addItemToCart(product),
          ),
        ),
      );
    } catch (e) {
      print('Error removing item from cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing from cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _proceedToCheckout() {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if user is authenticated
    final user = SupabaseService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to proceed with checkout'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to checkout page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          cartItems: cartItems,
          total: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _clearCart(),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage(initialTab: 0)),
              (route) => false,
            ),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...List.generate(
            cartItems.length,
            (index) {
              final cartItem = cartItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total (${cartItems.length} items)",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "\$${total.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _proceedToCheckout,
                      label: const Text("Proceed to Checkout"),
                      icon: const Icon(IconlyBold.arrowRight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DBService().clearCart();
                setState(() {
                  cartItems.clear();
                  total = 0.0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cart cleared'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error clearing cart: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
