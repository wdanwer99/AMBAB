import 'package:agriplant/models/order.dart';
import 'package:agriplant/models/product.dart';
import 'package:agriplant/pages/home_page.dart';
import 'package:agriplant/services/db_services.dart';
import 'package:agriplant/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class CheckoutPage extends StatefulWidget {
  final List<Product> cartItems;
  final double total;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isProcessing = false;

  double get subtotal => widget.total;
  double get tax => subtotal * 0.15; // 15% tax
  double get shipping => 10.0; // Fixed shipping cost
  double get total => subtotal + tax + shipping;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      final userData = await SupabaseService.getUser(user.id);
      if (userData != null) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone']?.toString() ?? '';
          _addressController.text = userData['location'] ?? '';
        });
      }
    }
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check stock for each product
      for (final product in widget.cartItems) {
        final dbProduct = await SupabaseService.getProductById(product.id!);
        if (dbProduct == null || dbProduct['quantity'] == null || dbProduct['quantity'] <= 0) {
          throw Exception('Product "${product.name}" is out of stock.');
        }
        if ((product.quantity ?? 1) > dbProduct['quantity']) {
          throw Exception('Not enough stock for "${product.name}". Available: ${dbProduct['quantity']}');
        }
      }

      // Convert cart items to order items
      final orderItems = widget.cartItems.map((product) {
        return OrderItem(
          productId: product.id ?? '',
          productName: product.name,
          productImage: product.image,
          price: product.price,
          quantity: product.quantity ?? 1,
          vendorId: product.vendorId,
          vendorName: product.vendorName,
          category: product.category,
        );
      }).toList();

      // Group items by vendor for vendor orders
      final vendorOrders = <String, String>{};
      final vendorGroups = <String, List<OrderItem>>{};
      
      for (final item in orderItems) {
        vendorGroups.putIfAbsent(item.vendorId, () => []).add(item);
      }

      // Create main order
      final order = Order(
        customerId: user.id,
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        customerAddress: _addressController.text.trim(),
        items: orderItems,
        subtotal: subtotal,
        tax: tax,
        shipping: shipping,
        total: total,
        status: 'Pending',
        paymentMethod: _selectedPaymentMethod,
        createdAt: DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        vendorOrders: vendorOrders,
      );

      // Create order in database
      final orderId = await SupabaseService.createOrder(order.toJson());

      // Decrease product stock
      await SupabaseService.decreaseProductStock(widget.cartItems.map((p) => {'productId': p.id, 'quantity': p.quantity ?? 1}).toList());

      // Clear cart
      await _clearCart();

      // Show success message and navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully! Order ID: ${orderId.substring(0, 8)}'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to order confirmation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationPage(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      print('Error processing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _clearCart() async {
    try {
      // Clear local cart database
      final dbService = DBService();
      await dbService.clearCart();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Shipping Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_shipping, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Shipping Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Order Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payment Method
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<String>(
                      title: const Text('Cash on Delivery'),
                      subtitle: const Text('Pay when you receive your order'),
                      value: 'Cash on Delivery',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Bank Transfer'),
                      subtitle: const Text('Transfer to our bank account'),
                      value: 'Bank Transfer',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...widget.cartItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${item.name} (${item.quantity}x)',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '\$${(item.price * (item.quantity ?? 1)).toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Divider(),
                    _buildSummaryRow('Subtotal', subtotal),
                    _buildSummaryRow('Tax (15%)', tax),
                    _buildSummaryRow('Shipping', shipping),
                    const Divider(),
                    _buildSummaryRow('Total', total, isTotal: true),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Place Order Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderConfirmationPage extends StatelessWidget {
  final String orderId;

  const OrderConfirmationPage({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 50,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Order ID: ${orderId.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const Text(
                'Thank you for your order! We will process it and contact you soon with delivery details.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Debug: Check user authentication
                        final user = SupabaseService.getCurrentUser();
                        print('Checkout: Current user - ${user?.id}');
                        print('Checkout: User email - ${user?.email}');
                        
                        if (user == null) {
                          print('Checkout: User is null, showing error');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Authentication error. Please login again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        print('Checkout: Navigating to home page');
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to orders page
                        Navigator.of(context).pushNamed('/orders');
                      },
                      child: const Text('View Orders'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 