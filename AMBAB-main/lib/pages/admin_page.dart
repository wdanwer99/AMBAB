import 'package:agriplant/services/supabase_service.dart';
import 'package:agriplant/pages/vendor_requests_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../l10n/app_localizations.dart';
import '../main.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  
  // Dashboard stats
  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _totalProducts = 0;
  int _pendingVendorRequests = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all data in parallel
      final futures = await Future.wait([
        SupabaseService.getOrders(),
        SupabaseService.getProducts(),
        SupabaseService.getPendingVendorRequests(),
      ]);

      final orders = futures[0] as List<Map<String, dynamic>>;
      final products = futures[1] as List<Map<String, dynamic>>;
      final vendorRequests = futures[2] as List<Map<String, dynamic>>;

      // Debug prints
      print('Admin: Total orders: ${orders.length}');
      print('Admin: Total products: ${products.length}');
      print('Admin: Pending vendor requests: ${vendorRequests.length}');
      print('Admin: Vendor requests data: $vendorRequests');

      // Calculate stats
      _totalOrders = orders.length;
      _pendingOrders = orders.where((order) => order['status'] == 'Pending').length;
      _totalProducts = products.length;
      _pendingVendorRequests = vendorRequests.length;
      
      // Calculate total revenue
      _totalRevenue = orders.fold(0.0, (sum, order) {
        return sum + (order['total'] as num? ?? 0.0);
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => showLanguagePicker(context),
            tooltip: loc.language,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: loc.logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: loc.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag),
            label: loc.myOrders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory),
            label: loc.services,
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.store),
                if (_pendingVendorRequests > 0)
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
                        '${_pendingVendorRequests > 99 ? '99+' : _pendingVendorRequests}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: loc.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildOrdersPage();
      case 2:
        return _buildProductsPage();
      case 3:
        return _buildVendorsPage();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 30,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, Admin!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Manage your agriculture marketplace',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  'Total Orders',
                  _totalOrders.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Pending Orders',
                  _pendingOrders.toString(),
                  Icons.schedule,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Total Products',
                  _totalProducts.toString(),
                  Icons.inventory,
                  Colors.green,
                ),
                _buildStatCard(
                  'Vendor Requests',
                  _pendingVendorRequests.toString(),
                  Icons.store,
                  Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Revenue Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Revenue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${_totalRevenue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Review Vendor Requests',
                    Icons.store,
                    Colors.purple,
                    () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                  ),
                ),
                // Add Product option removed for admin
              ],
            ),
            
            // Add bottom padding to prevent overflow
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: color,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersPage() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseService.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'Pending';
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            _getStatusIcon(status),
            color: statusColor,
          ),
        ),
        title: Text(
          'Order #${order['id'].toString().substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Customer: ${order['customer_name'] ?? 'N/A'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Total: \$${order['total']?.toStringAsFixed(2) ?? '0.00'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Status: $status',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
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
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Deletion"),
                  content: const Text("Are you sure you want to delete this order?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // TODO: Implement delete order functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete functionality not implemented yet')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildProductsPage() {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
      // FloatingActionButton for Add Product removed for admin
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product['image'] ?? '',
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
        title: Text(
          product['name'] ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Price: \$${product['price']?.toStringAsFixed(2) ?? '0.00'}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Vendor: ${product['vendor_name'] ?? 'Unknown'}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Category: ${product['category'] ?? 'Unknown'}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Status: ${product['is_available'] == true ? 'Available' : 'Unavailable'}",
              style: TextStyle(
                color: product['is_available'] == true ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              value: 'toggle',
              child: Row(
                children: [
                  Icon(Icons.toggle_on),
                  SizedBox(width: 8),
                  Text('Toggle Availability'),
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
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Deletion"),
                  content: Text("Are you sure you want to delete ${product['name']}?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                try {
                  await SupabaseService.deleteProduct(product['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted successfully')),
                  );
                  // Refresh the page
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting product: $e')),
                  );
                }
              }
            } else if (value == 'toggle') {
              try {
                await SupabaseService.updateProduct(
                  productId: product['id'],
                  updates: {
                    'is_available': !(product['is_available'] ?? true),
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product availability updated')),
                );
                // Refresh the page
                setState(() {});
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating product: $e')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildVendorsPage() {
    return const VendorRequestsPage();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _createTestVendor() async {
    try {
      await SupabaseService.createVendorRequest(
        name: 'Test Vendor',
        email: 'test@example.com',
        phone: '123-456-7890',
        address: '123 Test St, Test City, TC 12345',
        description: 'This is a test vendor request for development purposes.',
        status: 'Pending',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test vendor request created successfully!')),
      );
      _loadDashboardStats(); // Refresh stats to show new request
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating test vendor request: $e')),
      );
    }
  }
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  File? _image;
  String _selectedCategory = 'اسمده';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final name = _nameController.text;
        final description = _descriptionController.text;
        final price = double.tryParse(_priceController.text) ?? 0.0;
        final quantity = int.tryParse(_quantityController.text) ?? 100;

        String imageUrl = '';
        if (_image != null) {
          imageUrl = await SupabaseService.uploadFile(
            file: _image!,
            path: 'admin-products',
          );
        }

        await SupabaseService.createProduct(
          name: name,
          description: description,
          price: price,
          quantity: quantity,
          image: imageUrl,
          category: _selectedCategory,
          vendorId: 'admin',
          vendorName: 'Admin Store',
          vendorStoreName: 'Admin Store',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding product: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _image!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 50, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'No image selected',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Select Image"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.productName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterProductName;
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              // TextFormField(
              //   controller: _descriptionController,
              //   decoration: InputDecoration(
              //     labelText: loc.description,
              //     border: const OutlineInputBorder(),
              //     prefixIcon: const Icon(Icons.description),
              //   ),
              //   maxLines: 3,
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return loc.pleaseEnterDescription;
              //     }
              //     return null;
              //   },
              // ),
              
              const SizedBox(height: 16),
              
              // Price and Quantity Row
              Row(
                children: [
                  // Expanded(
                  //   child: TextFormField(
                  //     controller: _priceController,
                  //     decoration: InputDecoration(
                  //       labelText: '${loc.price} (\$${loc.currency})',
                  //       border: const OutlineInputBorder(),
                  //       prefixIcon: const Icon(Icons.attach_money),
                  //     ),
                  //     keyboardType: TextInputType.number,
                  //     validator: (value) {
                  //       if (value == null || value.isEmpty) {
                  //         return loc.pleaseEnterPrice;
                  //       }
                  //       if (double.tryParse(value) == null) {
                  //         return loc.pleaseEnterValidNumber;
                  //       }
                  //       return null;
                  //     },
                  //   ),
                  // ),
                  const SizedBox(width: 16),
                  // Expanded(
                  //   child: TextFormField(
                  //     controller: _quantityController,
                  //     decoration: InputDecoration(
                  //       labelText: loc.quantity,
                  //       border: const OutlineInputBorder(),
                  //       prefixIcon: const Icon(Icons.numbers),
                  //     ),
                  //     keyboardType: TextInputType.number,
                  //     validator: (value) {
                  //       if (value == null || value.isEmpty) {
                  //         return loc.pleaseEnterQuantity;
                  //       }
                  //       if (int.tryParse(value) == null) {
                  //         return loc.pleaseEnterValidNumber;
                  //       }
                  //       return null;
                  //     },
                  //   ),
                  // ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Category
              // DropdownButtonFormField<String>(
              //   value: _selectedCategory,
              //   decoration: InputDecoration(
              //     labelText: loc.category,
              //     border: const OutlineInputBorder(),
              //     prefixIcon: const Icon(Icons.category),
              //   ),
              //   items: [
              //     DropdownMenuItem(value: 'اسمده', child: Text(loc.fertilizer)),
              //     DropdownMenuItem(value: 'مبيدات', child: Text(loc.pesticides)),
              //     DropdownMenuItem(value: 'بذور', child: Text(loc.seeds)),
              //     DropdownMenuItem(value: 'معدات', child: Text(loc.equipment)),
              //     DropdownMenuItem(value: 'شتلات', child: Text(loc.transplants)),
              //     DropdownMenuItem(value: 'أخرى', child: Text(loc.other)),
              //   ],
              //   onChanged: (value) {
              //     setState(() {
              //       _selectedCategory = value!;
              //     });
              //   },
              // ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              // SizedBox(
              //   width: double.infinity,
              //   height: 50,
              //   child: ElevatedButton(
              //     onPressed: _isLoading ? null : _addProduct,
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.green.shade700,
              //       foregroundColor: Colors.white,
              //     ),
              //     child: _isLoading
              //         ? const CircularProgressIndicator(color: Colors.white)
              //         : Text(
              //             loc.addProduct,
              //             style: const TextStyle(fontSize: 16),
              //           ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
