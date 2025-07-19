import 'package:agriplant/models/product.dart';
import 'package:agriplant/models/vendor.dart';
import 'package:agriplant/pages/vendor_add_product_page.dart';
import 'package:agriplant/pages/vendor_orders_page.dart';
import 'package:agriplant/pages/vendor_profile_page.dart';
import 'package:agriplant/pages/vendor_pending_approval_page.dart';
import 'package:agriplant/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class VendorDashboardPage extends StatefulWidget {
  const VendorDashboardPage({super.key});

  @override
  State<VendorDashboardPage> createState() => _VendorDashboardPageState();
}

class _VendorDashboardPageState extends State<VendorDashboardPage> {
  Vendor? vendor;
  List<Product> products = [];
  bool isLoading = true;
  int pendingOrdersCount = 0;
  double totalSales = 0.0;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      try {
        // Check if vendor is approved
        final isApproved = await SupabaseService.isVendorApproved(user.id);
        if (!isApproved) {
          // Redirect to pending approval page
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const VendorPendingApprovalPage(),
              ),
            );
          }
          return;
        }

        // Load vendor data
        final vendorData = await SupabaseService.getVendor(user.id);
        
        if (vendorData != null) {
          setState(() {
            vendor = Vendor.fromJson(vendorData);
          });
        }

        // Load vendor products
        final productsData = await SupabaseService.getProducts(vendorId: user.id);

        // Load pending orders count
        await _loadPendingOrdersCount();

        // Calculate total sales from completed orders
        final calculatedSales = await SupabaseService.getVendorTotalSales(user.id);

        setState(() {
          products = productsData
              .map((doc) => Product.fromJson({...doc, 'id': doc['id']}))
              .toList();
          totalSales = calculatedSales;
          isLoading = false;
        });
      } catch (e) {
        print('Error loading vendor data: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPendingOrdersCount() async {
    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) return;

      final allOrders = await SupabaseService.getOrders();
      
      // Count pending orders that contain products from this vendor
      final pendingCount = allOrders.where((order) {
        if (order['status'] != 'Pending') return false;
        
        final items = order['items'] as List<dynamic>? ?? [];
        return items.any((item) => item['vendor_id'] == user.id);
      }).length;

      setState(() {
        pendingOrdersCount = pendingCount;
      });
    } catch (e) {
      print('Error loading pending orders count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Notify and block disabled vendors
    if (vendor != null && vendor!.isDisabled == true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Disabled'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, color: Colors.orange, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Your vendor account has been disabled by the admin.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please contact support or the admin for more information.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  onPressed: () async {
                    await SupabaseService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(vendor?.storeName ?? 'Vendor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VendorProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadVendorData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.green.shade100,
                            child: Icon(
                              Icons.store,
                              size: 30,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor?.storeName ?? 'Store Name',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  vendor?.storeDescription ?? 'Store Description',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 16),
                                    Text(' ${vendor?.rating.toStringAsFixed(1) ?? '0.0'}'),
                                    const SizedBox(width: 16),
                                    Icon(Icons.location_on, color: Colors.grey, size: 16),
                                    Text(' ${vendor?.location ?? 'Location'}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Products',
                      '${products.length}',
                      Icons.inventory,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Sales',
                      '\$${totalSales.toStringAsFixed(2)}',
                      Icons.shopping_cart,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Products Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VendorAddProductPage(),
                        ),
                      ).then((_) => _loadVendorData());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              if (products.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by adding your first product',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.image,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              );
                            },
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\$${product.price.toStringAsFixed(2)}'),
                            Text(
                              'Stock: ${product.quantity}',
                              style: TextStyle(
                                color: product.quantity > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'stock',
                              child: Row(
                                children: [
                                  Icon(Icons.inventory),
                                  SizedBox(width: 8),
                                  Text('Update Stock'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text('Are you sure you want to delete ${product.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await SupabaseService.deleteProduct(product.id!);
                                _loadVendorData();
                              }
                            } else if (value == 'stock') {
                              final controller = TextEditingController(text: product.quantity.toString());
                              final result = await showDialog<int>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Update Stock for ${product.name}'),
                                  content: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'New Stock Quantity'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final qty = int.tryParse(controller.text);
                                        if (qty != null && qty >= 0) {
                                          Navigator.pop(context, qty);
                                        }
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              );
                              if (result != null) {
                                await SupabaseService.updateProduct(
                                  productId: product.id!,
                                  updates: {
                                    'quantity': result,
                                    'is_available': result > 0,
                                  },
                                );
                                _loadVendorData();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Stock updated for ${product.name}'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VendorOrdersPage(),
              ),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_bag),
                if (pendingOrdersCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        pendingOrdersCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Orders',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VendorAddProductPage(),
            ),
          ).then((_) => _loadVendorData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 