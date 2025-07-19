import 'package:agriplant/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class VendorOrdersPage extends StatefulWidget {
  const VendorOrdersPage({super.key});

  @override
  State<VendorOrdersPage> createState() => _VendorOrdersPageState();
}

class _VendorOrdersPageState extends State<VendorOrdersPage> {
  String _selectedStatus = 'All';
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final orders = await _getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          // Debug button to test order access
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _debugOrderAccess,
            tooltip: 'Debug Order Access',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Filter by status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: [
                      'All',
                      'Pending',
                      'Confirmed',
                      'Shipped',
                      'Delivered',
                      'Cancelled',
                    ].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                      _loadOrders(); // Refresh orders when filter changes
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No orders yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Orders for your products will appear here',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                                            : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${order['id'].toString().substring(0, 8)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (order['status'] == 'Cancelled')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'CANCELLED',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer: ${order['customer_name'] ?? 'N/A'}'),
                            Text('Date: ${_formatDate(order['created_at'])}'),
                            Text(
                              'Status: ${order['status'] ?? 'Pending'}',
                              style: TextStyle(
                                color: _getStatusColor(order['status']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Products in this order
                                const Text(
                                  'Products:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._buildProductList(order['items'] ?? []),
                                
                                const SizedBox(height: 16),
                                
                                // Order details
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total: \$${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (order['status'] == 'Pending')
                                      ElevatedButton(
                                        onPressed: () => _updateOrderStatus(
                                          order['id'],
                                          'Confirmed',
                                        ),
                                        child: const Text('Confirm Order'),
                                      ),
                                  ],
                                ),
                                
                                // Cancelled order notice
                                if (order['status'] == 'Cancelled') ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(color: Colors.red.shade200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'This order was cancelled by the customer',
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 16),
                                
                                // Status update buttons (disabled for cancelled orders)
                                if (order['status'] == 'Confirmed' && order['status'] != 'Cancelled')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateOrderStatus(
                                            order['id'],
                                            'Shipped',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                          child: const Text('Mark as Shipped'),
                                        ),
                                      ),
                                    ],
                                  ),
                                
                                if (order['status'] == 'Shipped' && order['status'] != 'Cancelled')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateOrderStatus(
                                            order['id'],
                                            'Delivered',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('Mark as Delivered'),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getOrders() async {
    final user = SupabaseService.getCurrentUser();
    if (user == null) {
      return [];
    }

    try {
      final allOrders = await SupabaseService.getOrders();
      
      // Filter orders that contain products from this vendor
      final vendorOrders = allOrders.where((order) {
        final items = order['items'] as List<dynamic>? ?? [];
        return items.any((item) => item['vendor_id'] == user.id);
      }).toList();

      // Filter by status if needed
      if (_selectedStatus != 'All') {
        return vendorOrders.where((order) => order['status'] == _selectedStatus).toList();
      }

      return vendorOrders;
    } catch (e) {
      print('Error getting vendor orders: $e');
      return [];
    }
  }

  List<Widget> _buildProductList(List<dynamic> items) {
    final user = SupabaseService.getCurrentUser();
    if (user == null) return [];
    
    // Filter items that belong to this vendor
    final vendorItems = items.where((item) {
      final itemData = item as Map<String, dynamic>;
      return itemData['vendor_id'] == user.id;
    }).toList();
    
    return vendorItems.map<Widget>((item) {
      final itemData = item as Map<String, dynamic>;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                itemData['product_image'] ?? '',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 20),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemData['product_name'] ?? 'Unknown Product',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Qty: ${itemData['quantity'] ?? 1} × \$${itemData['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    'Total: \$${((itemData['price'] ?? 0.0) * (itemData['quantity'] ?? 1)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    if (timestamp is String) {
      try {
        final date = DateTime.parse(timestamp);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
      } catch (e) {
        return 'N/A';
      }
    }
    
    return 'N/A';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      print('VendorOrdersPage: Updating order $orderId to status: $newStatus');
      
      // Get current order status for verification
      final currentOrder = await SupabaseService.getOrder(orderId);
      if (currentOrder != null) {
        print('VendorOrdersPage: Current order status: ${currentOrder['status']}');
      }
      
      await SupabaseService.updateOrderStatus(
        orderId: orderId,
        status: newStatus,
      );

      print('VendorOrdersPage: Order status update completed');

      // Verify the update by fetching the order again
      final updatedOrder = await SupabaseService.getOrder(orderId);
      if (updatedOrder != null) {
        print('VendorOrdersPage: Updated order status: ${updatedOrder['status']}');
        if (updatedOrder['status'] != newStatus) {
          throw Exception('Status update verification failed. Expected: $newStatus, Got: ${updatedOrder['status']}');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Refresh the orders list
      await _loadOrders();
      
      // Show confirmation dialog for important status changes
      if (newStatus == 'Confirmed') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Order Confirmed!'),
              content: const Text('The order has been confirmed. You can now proceed with shipping when ready.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('VendorOrdersPage: Error updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order status: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _debugOrderAccess() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      print('Debug: User ID: ${user.id}');
      
      // Test getting all orders
      final allOrders = await SupabaseService.getOrders();
      print('Debug: Total orders in system: ${allOrders.length}');
      
      // Test getting vendor orders
      final vendorOrders = allOrders.where((order) {
        final items = order['items'] as List<dynamic>? ?? [];
        return items.any((item) => item['vendor_id'] == user.id);
      }).toList();
      
      print('Debug: Orders for this vendor: ${vendorOrders.length}');
      
      if (vendorOrders.isNotEmpty) {
        final firstOrder = vendorOrders.first;
        print('Debug: First order ID: ${firstOrder['id']}');
        print('Debug: First order status: ${firstOrder['status']}');
        
        // Test updating the first order
        try {
          await SupabaseService.updateOrderStatus(
            orderId: firstOrder['id'],
            status: 'TestStatus',
          );
          print('Debug: Order update test PASSED');
          
          // Restore original status
          await SupabaseService.updateOrderStatus(
            orderId: firstOrder['id'],
            status: firstOrder['status'],
          );
          print('Debug: Order status restored');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debug: Order update test PASSED'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          print('Debug: Order update test FAILED: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Debug: Order update test FAILED: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug: No orders found for this vendor'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Debug error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug error: $e')),
      );
    }
  }
} 