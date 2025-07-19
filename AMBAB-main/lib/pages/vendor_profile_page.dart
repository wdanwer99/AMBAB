import 'package:agriplant/models/vendor.dart';
import 'package:agriplant/pages/auth_service.dart';
import 'package:agriplant/pages/login_page.dart';
import 'package:agriplant/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({super.key});

  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  Vendor? vendor;
  bool isLoading = true;
  bool isEditing = false;
  double totalSales = 0.0;
  
  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _storeNameController;
  late TextEditingController _storeDescriptionController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadVendorData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _storeNameController = TextEditingController();
    _storeDescriptionController = TextEditingController();
    _locationController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      try {
        final vendorData = await SupabaseService.getVendor(user.id);
        
        if (vendorData != null) {
          setState(() {
            vendor = Vendor.fromJson(vendorData);
          });
          
          // Calculate total sales from completed orders
          final calculatedSales = await SupabaseService.getVendorTotalSales(user.id);
          
          setState(() {
            totalSales = calculatedSales;
            isLoading = false;
          });
          
          _populateControllers();
        }
      } catch (e) {
        print('Error loading vendor data: $e');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _populateControllers() {
    if (vendor != null) {
      _nameController.text = vendor!.name;
      _storeNameController.text = vendor!.storeName ?? '';
      _storeDescriptionController.text = vendor!.storeDescription ?? '';
      _locationController.text = vendor!.location;
      _phoneController.text = vendor!.phone;
    }
  }

  Future<void> _updateProfile() async {
    if (vendor == null) return;

    try {
      final user = SupabaseService.getCurrentUser();
      if (user == null) return;

      await SupabaseService.updateVendor(
        vendorId: user.id,
        updates: {
          'name': _nameController.text.trim(),
          'store_name': _storeNameController.text.trim(),
          'store_description': _storeDescriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'phone': int.tryParse(_phoneController.text.trim()) ?? vendor!.phone,
        },
      );

      setState(() {
        isEditing = false;
      });

      _loadVendorData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (vendor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('Vendor data not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        Icons.store,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vendor!.storeName ?? 'Store Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vendor!.storeDescription ?? 'Store Description',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          'Rating',
                          '${vendor!.rating.toStringAsFixed(1)}',
                          Icons.star,
                          Colors.amber,
                        ),
                        _buildStatItem(
                          'Products',
                          '${vendor!.totalProducts}',
                          Icons.inventory,
                          Colors.blue,
                        ),
                        _buildStatItem(
                          'Sales',
                          '\$${totalSales.toStringAsFixed(2)}',
                          Icons.shopping_cart,
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Profile Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Store Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isEditing)
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isEditing = false;
                                    _populateControllers();
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: _updateProfile,
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildInfoField(
                      'Store Name',
                      _storeNameController,
                      Icons.store,
                      isEditing: isEditing,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoField(
                      'Store Description',
                      _storeDescriptionController,
                      Icons.description,
                      isEditing: isEditing,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoField(
                      'Owner Name',
                      _nameController,
                      Icons.person,
                      isEditing: isEditing,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoField(
                      'Location',
                      _locationController,
                      Icons.location_on,
                      isEditing: isEditing,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoField(
                      'Phone',
                      _phoneController,
                      Icons.phone,
                      isEditing: isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildInfoField(
                      'Email',
                      TextEditingController(text: vendor!.email),
                      Icons.email,
                      isEditing: false, // Email cannot be edited
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Icon(Icons.verified, color: vendor!.isVerified ? Colors.green : Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          vendor!.isVerified ? 'Verified Store' : 'Pending Verification',
                          style: TextStyle(
                            color: vendor!.isVerified ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to settings page
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to help page
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to about page
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isEditing = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        if (isEditing)
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              border: const OutlineInputBorder(),
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Not provided' : controller.text,
                    style: TextStyle(
                      color: controller.text.isEmpty ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
} 