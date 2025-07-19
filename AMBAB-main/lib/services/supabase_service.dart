import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agriplant/models/product.dart';
import 'package:agriplant/models/vendor.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Authentication methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: userData,
    );
    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  static Future<String?> getCurrentUserRole() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;
      
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      
      return response['role'];
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // User management
  static Future<void> createUser({
    required String userId,
    required String name,
    required String email,
    required String location,
    required int phone,
    required String role,
  }) async {
    try {
      print('Creating user with ID: $userId');
      print('User data: name=$name, email=$email, location=$location, phone=$phone, role=$role');
      
      // Try with anon key first
      try {
        final response = await _supabase.from('users').insert({
          'id': userId,
          'name': name,
          'email': email,
          'location': location,
          'phone': phone,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('User created successfully: $response');
      } catch (e) {
        print('Error with anon key, trying alternative approach: $e');
        // If that fails, try a different approach
        final response = await _supabase.from('users').upsert({
          'id': userId,
          'name': name,
          'email': email,
          'location': location,
          'phone': phone,
          'role': role,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('User upserted successfully: $response');
      }
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  // Vendor management
  static Future<void> createVendor({
    required String userId,
    required String name,
    required String email,
    required String location,
    required int phone,
    required String storeName,
    required String storeDescription,
  }) async {
    try {
      final response = await _supabase.from('vendors').insert({
        'id': userId,
        'name': name,
        'email': email,
        'location': location,
        'phone': phone,
        'store_name': storeName,
        'store_description': storeDescription,
        'is_verified': false,
        'is_approved': false,
        'approval_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'rating': 0.0,
        'total_products': 0,
        'total_sales': 0,
      });
      
      print('Vendor created successfully: $response');
    } catch (e) {
      print('Error creating vendor: $e');
      rethrow;
    }
  }

  // Test method for creating vendor requests
  static Future<void> createVendorRequest({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String description,
    required String status,
  }) async {
    try {
      final testUserId = 'test-vendor-${DateTime.now().millisecondsSinceEpoch}';
      final response = await _supabase.from('vendors').insert({
        'id': testUserId,
        'name': name,
        'email': email,
        'location': address,
        'phone': phone,
        'store_name': '$name Store',
        'store_description': description,
        'is_verified': false,
        'is_approved': false,
        'approval_status': status.toLowerCase(),
        'created_at': DateTime.now().toIso8601String(),
        'rating': 0.0,
        'total_products': 0,
        'total_sales': 0,
      });
      
      print('Test vendor request created successfully: $response');
    } catch (e) {
      print('Error creating test vendor request: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getVendor(String vendorId) async {
    final response = await _supabase
        .from('vendors')
        .select()
        .eq('id', vendorId)
        .single();
    return response;
  }

  // Vendor approval methods
  static Future<List<Map<String, dynamic>>> getPendingVendorRequests() async {
    try {
      print('SupabaseService: Getting pending vendor requests...');
      
      // Check current user and role
      final user = getCurrentUser();
      final userRole = await getCurrentUserRole();
      print('SupabaseService: Current user: ${user?.id}');
      print('SupabaseService: Current user role: $userRole');
      
      // First, let's try to get all vendors to see if RLS is blocking us
      try {
        final allVendors = await _supabase
            .from('vendors')
            .select()
            .order('created_at', ascending: false);
        print('SupabaseService: All vendors count: ${allVendors.length}');
        print('SupabaseService: All vendors: $allVendors');
      } catch (e) {
        print('SupabaseService: Error getting all vendors: $e');
      }
      
      final response = await _supabase
          .from('vendors')
          .select()
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);
      
      print('SupabaseService: Raw response: $response');
      final result = List<Map<String, dynamic>>.from(response);
      print('SupabaseService: Parsed result: $result');
      return result;
    } catch (e) {
      print('Error getting pending vendor requests: $e');
      return [];
    }
  }

  // Fetch all vendors (for admin)
  static Future<List<Map<String, dynamic>>> getAllVendors() async {
    try {
      final response = await _supabase
          .from('vendors')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all vendors: $e');
      return [];
    }
  }

  static Future<void> approveVendor(String vendorId) async {
    try {
      await _supabase
          .from('vendors')
          .update({
            'is_approved': true,
            'approval_status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);
      
      // Also update the user role to 'vendor' (without updated_at if it doesn't exist)
      try {
        await _supabase
            .from('users')
            .update({
              'role': 'vendor',
            })
            .eq('id', vendorId);
      } catch (e) {
        print('Warning: Could not update user role (updated_at column might not exist): $e');
        // Try without updated_at column
        try {
          await _supabase
              .from('users')
              .update({
                'role': 'vendor',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', vendorId);
        } catch (e2) {
          print('Error updating user role: $e2');
        }
      }
      
      print('Vendor approved successfully: $vendorId');
    } catch (e) {
      print('Error approving vendor: $e');
      rethrow;
    }
  }

  static Future<void> rejectVendor(String vendorId, String reason) async {
    try {
      await _supabase
          .from('vendors')
          .update({
            'is_approved': false,
            'approval_status': 'rejected',
            'rejection_reason': reason,
            'rejected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);
      
      print('Vendor rejected successfully: $vendorId');
    } catch (e) {
      print('Error rejecting vendor: $e');
      rethrow;
    }
  }

  static Future<bool> isVendorApproved(String vendorId) async {
    try {
      final vendor = await getVendor(vendorId);
      return vendor?['is_approved'] == true && vendor?['approval_status'] == 'approved';
    } catch (e) {
      print('Error checking vendor approval status: $e');
      return false;
    }
  }

  static Future<void> updateVendor({
    required String vendorId,
    required Map<String, dynamic> updates,
  }) async {
    await _supabase
        .from('vendors')
        .update(updates)
        .eq('id', vendorId);
  }

  // Product management
  static Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String image,
    required String category,
    required String vendorId,
    required String vendorName,
    String? vendorStoreName,
  }) async {
    await _supabase.from('products').insert({
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'image': image,
      'category': category,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'vendor_store_name': vendorStoreName,
      'is_available': true,
      'created_at': DateTime.now().toIso8601String(),
      'rating': 0.0,
      'total_sold': 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getProducts({
    String? category,
    String? vendorId,
  }) async {
    var query = _supabase.from('products').select('*, vendors!inner(is_disabled)');
    
    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }
    
    if (vendorId != null) {
      query = query.eq('vendor_id', vendorId);
    }
    
    // Only include products where the vendor is not disabled
    query = query.eq('vendors.is_disabled', false);
    
    final response = await query.eq('is_available', true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> updates,
  }) async {
    await _supabase
        .from('products')
        .update(updates)
        .eq('id', productId);
  }

  static Future<void> deleteProduct(String productId) async {
    await _supabase
        .from('products')
        .delete()
        .eq('id', productId);
  }

  // Order management
  static Future<String> createOrder(Map<String, dynamic> orderData) async {
    try {
      // Extract only the basic fields that exist in the orders table
      final basicOrderData = {
        'customer_id': orderData['customer_id'],
        'customer_name': orderData['customer_name'],
        'customer_email': orderData['customer_email'],
        'customer_phone': orderData['customer_phone'],
        'customer_address': orderData['customer_address'],
        'items': orderData['items'],
        'subtotal': orderData['subtotal'],
        'tax': orderData['tax'],
        'shipping': orderData['shipping'],
        'total': orderData['total'],
        'status': orderData['status'],
        'payment_method': orderData['payment_method'],
        'notes': orderData['notes'],
        'created_at': orderData['created_at'],
      };
      
      final response = await _supabase
          .from('orders')
          .insert(basicOrderData)
          .select()
          .single();
      return response['id'];
    } catch (e) {
      print('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getOrders({
    String? customerId,
    String? vendorId,
    String? status,
  }) async {
    try {
      var query = _supabase.from('orders').select();
      
      if (customerId != null) {
        query = query.eq('customer_id', customerId);
      }
      
      if (vendorId != null) {
        query = query.contains('vendor_orders', {vendorId: 'any'});
      }
      
      if (status != null && status != 'All') {
        query = query.eq('status', status);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting orders: $e');
      return [];
    }
  }

  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      print('SupabaseService: Updating order $orderId to status: $status');
      // First check if the order exists
      final existingOrder = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .maybeSingle();
      if (existingOrder == null) {
        throw Exception('Order not found with ID: $orderId');
      }
      print('SupabaseService: Found order with current status: ${existingOrder['status']}');
      // Check if order can be cancelled (only pending orders can be cancelled by customer)
      if (status == 'Cancelled' && existingOrder['status'] != 'Pending') {
        throw Exception('Only pending orders can be cancelled');
      }
      // Update the order status
      final response = await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select()
          .single();
      print('SupabaseService: Order status updated successfully. New status: ${response['status']}');
      // Verify the update worked
      if (response['status'] != status) {
        throw Exception('Status update failed. Expected: $status, Got: ${response['status']}');
      }
      print('SupabaseService: Status update verified successfully');
      // Decrease product stock only when order is delivered
      if (status == 'Delivered') {
        final items = (existingOrder['items'] as List<dynamic>?) ?? [];
        final stockItems = items.map((item) => {
          'productId': item['productId'] ?? item['id'],
          'quantity': item['quantity'] ?? 1,
        }).toList();
        await decreaseProductStock(stockItems);
        
        // Update total sales for all vendors in this order
        final vendorIds = items.map((item) => item['vendor_id']).toSet();
        for (final vendorId in vendorIds) {
          if (vendorId != null) {
            await updateVendorTotalSales(vendorId);
          }
        }
      }
    } catch (e) {
      print('SupabaseService: Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  static Future<void> cancelOrder({
    required String orderId,
    required String customerId,
  }) async {
    try {
      print('SupabaseService: Cancelling order $orderId by customer $customerId');
      
      // First check if the order exists and belongs to the customer
      final existingOrder = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .eq('customer_id', customerId)
          .maybeSingle();
      
      if (existingOrder == null) {
        throw Exception('Order not found or does not belong to you');
      }
      
      // Check if order can be cancelled (only pending orders can be cancelled)
      if (existingOrder['status'] != 'Pending') {
        throw Exception('Only pending orders can be cancelled');
      }
      
      // Update the order status to cancelled
      final response = await _supabase
          .from('orders')
          .update({
            'status': 'Cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('customer_id', customerId)
          .select()
          .single();
      
      print('SupabaseService: Order cancelled successfully. New status: ${response['status']}');
      
    } catch (e) {
      print('SupabaseService: Error cancelling order: $e');
      throw Exception('Failed to cancel order: $e');
    }
  }

  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();
      return response;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Calculate total sales from completed orders for a vendor
  static Future<double> getVendorTotalSales(String vendorId) async {
    try {
      print('Calculating total sales for vendor: $vendorId');
      
      // Get all delivered orders
      final deliveredOrders = await _supabase
          .from('orders')
          .select()
          .eq('status', 'Delivered')
          .order('created_at', ascending: false);
      
      double totalSales = 0.0;
      
      for (final order in deliveredOrders) {
        final items = order['items'] as List<dynamic>? ?? [];
        
        // Calculate sales for items from this vendor
        for (final item in items) {
          if (item['vendor_id'] == vendorId) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            totalSales += price * quantity;
          }
        }
      }
      
      print('Total sales calculated for vendor $vendorId: \$${totalSales.toStringAsFixed(2)}');
      return totalSales;
    } catch (e) {
      print('Error calculating vendor total sales: $e');
      return 0.0;
    }
  }

  // Update vendor's total_sales field in database
  static Future<void> updateVendorTotalSales(String vendorId) async {
    try {
      print('Updating total sales for vendor: $vendorId');
      
      // Calculate total sales from completed orders
      final totalSales = await getVendorTotalSales(vendorId);
      
      // Update the vendor's total_sales field
      await _supabase
          .from('vendors')
          .update({
            'total_sales': totalSales.toInt(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);
      
      print('Vendor total sales updated successfully: \$${totalSales.toStringAsFixed(2)}');
    } catch (e) {
      print('Error updating vendor total sales: $e');
    }
  }

  // Saved products
  static Future<void> saveProduct({
    required String userId,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    await _supabase.from('saved_products').insert({
      'user_id': userId,
      'product_id': productId,
      'product_data': productData,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getSavedProducts(String userId) async {
    final response = await _supabase
        .from('saved_products')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> deleteSavedProduct({
    required String userId,
    required String productId,
  }) async {
    await _supabase
        .from('saved_products')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  // File upload
  static Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      print('Starting file upload...');
      print('File path: ${file.path}');
      print('Upload path: $path');
      
      final user = SupabaseService.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      print('User authenticated: ${user.id}');
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final filePath = '$path/$fileName';
      
      print('Uploading to: $filePath');
      
      // Upload the file
      final uploadResponse = await _supabase.storage
          .from('product-images')
          .upload(filePath, file);
      
      print('Upload response: $uploadResponse');
      
      // Get the public URL
      final imageUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(filePath);
      
      print('Public URL: $imageUrl');
      
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print('Error details: ${e.toString()}');
      rethrow;
    }
  }

  // Disable a vendor (set is_disabled to true)
  static Future<void> disableVendor(String vendorId) async {
    try {
      await _supabase
          .from('vendors')
          .update({'is_disabled': true})
          .eq('id', vendorId);
      print('Vendor disabled: $vendorId');
    } catch (e) {
      print('Error disabling vendor: $e');
      rethrow;
    }
  }

  // Enable a vendor (set is_disabled to false)
  static Future<void> enableVendor(String vendorId) async {
    try {
      await _supabase
          .from('vendors')
          .update({'is_disabled': false})
          .eq('id', vendorId);
      print('Vendor enabled: $vendorId');
    } catch (e) {
      print('Error enabling vendor: $e');
      rethrow;
    }
  }

  // Delete all products for a vendor
  static Future<void> deleteAllProductsForVendor(String vendorId) async {
    try {
      await _supabase
          .from('products')
          .delete()
          .eq('vendor_id', vendorId);
      print('Deleted all products for vendor: $vendorId');
    } catch (e) {
      print('Error deleting products for vendor: $e');
      rethrow;
    }
  }

  // Decrease product stock for a list of productId/quantity pairs
  static Future<void> decreaseProductStock(List<Map<String, dynamic>> items) async {
    for (final item in items) {
      final productId = item['productId'] ?? item['id'];
      final quantity = item['quantity'] ?? 1;
      if (productId != null) {
        // Get current product
        final product = await _supabase.from('products').select('quantity').eq('id', productId).maybeSingle();
        if (product != null && product['quantity'] != null) {
          final newQuantity = (product['quantity'] as int) - (quantity as int);
          await _supabase.from('products').update({
            'quantity': newQuantity < 0 ? 0 : newQuantity,
            'is_available': newQuantity > 0,
          }).eq('id', productId);
        }
      }
    }
  }

  // Get a product by its id
  static Future<Map<String, dynamic>?> getProductById(String productId) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('id', productId)
        .maybeSingle();
    return response;
  }
} 