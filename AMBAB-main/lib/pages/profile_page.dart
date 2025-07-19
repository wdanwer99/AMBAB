import 'package:agriplant/models/product.dart';
import 'package:agriplant/pages/login_page.dart';
import 'package:agriplant/pages/orders_page.dart';
import 'package:agriplant/pages/about_us_page.dart';
import 'package:agriplant/pages/saved_products_page.dart';
import 'package:agriplant/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:agriplant/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String userEmail = '';
  List<Product> savedProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchSavedProducts();
  }

  Future<void> _fetchUserData() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      final userData = await SupabaseService.getUser(user.id);
      if (userData != null) {
        setState(() {
          userName = userData['name'] ?? '';
          userEmail = userData['email'] ?? '';
        });
      }
    }
  }

  Future<void> _fetchSavedProducts() async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      final savedProductsData = await SupabaseService.getSavedProducts(user.id);

      final products = savedProductsData.map((doc) {
        final productData = doc['product_data'] as Map<String, dynamic>;
        return Product(
          id: productData['id'] ?? '',
          name: productData['name'] ?? '',
          price: (productData['price'] ?? 0.0).toDouble(),
          quantity: productData['quantity'] ?? 1,
          image: productData['image'] ?? '',
          description: productData['description'] ?? '',
          category: productData['category'] ?? '',
          vendorId: productData['vendor_id'] ?? 'unknown',
          vendorName: productData['vendor_name'] ?? 'Unknown Vendor',
          createdAt: DateTime.now(), // Default timestamp
        );
      }).toList();

      setState(() {
        savedProducts = products;
      });
    }
  }

  Future<void> _deleteSavedProduct(String productId) async {
    final user = SupabaseService.getCurrentUser();
    if (user != null) {
      await SupabaseService.deleteSavedProduct(
        userId: user.id,
        productId: productId,
      );

      setState(() {
        savedProducts.removeWhere((product) => product.id == productId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 15),
            child: CircleAvatar(
              radius: 62,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const CircleAvatar(
                radius: 60,
                foregroundImage: AssetImage('assets/profile.jpg'),
              ),
            ),
          ),
          Center(
            child: Text(
              userName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Center(
            child: Text(
              userEmail,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 25),
          ListTile(
            title: const Text("My orders"),
            leading: const Icon(IconlyLight.bag),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrdersPage(),
                  ));
            },
          ),
          ListTile(
            title: const Text("Saved Products"),
            leading: const Icon(IconlyLight.bookmark),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedProductsPage(
                    savedProducts: savedProducts,
                    deleteProduct: _deleteSavedProduct,
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text("About us"),
            leading: const Icon(IconlyLight.infoSquare),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutUsPage(),
                  ));
            },
          ),
          ListTile(
            title: const Text("Logout"),
            leading: const Icon(IconlyLight.logout),
            onTap: () async {
              await SupabaseService.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// class SavedProductsPage extends StatelessWidget {
//   final List<Product> savedProducts;
//   final Future<void> Function(String) deleteProduct;

//   // const SavedProductsPage({
//   //   super.key,
//   //   required this.savedProducts,
//   //   required this.deleteProduct,
//   // });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Saved Products"),
//       ),
//       body: ListView.builder(
//         itemCount: savedProducts.length,
//         itemBuilder: (context, index) {
//           final product = savedProducts[index];
//           return ListTile(
//             leading: Image.network(product.image),
//             title: Text(product.name),
//             subtitle: Text("\$${product.price}"),
//             trailing: IconButton(
//               icon: const Icon(Icons.delete),
//               onPressed: () async {
//                 await deleteProduct(product.id);
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class UserService {
//   static Future<UserData> getUser() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final userData = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//       return UserData(
//         name: userData['name'],
//         email: userData['email'],
//         location: userData['location'],
//         phone: userData['phone'],
//       );
//     } else {
//       throw Exception('No user signed in');
//     }
//   }
// }

// class UserData {
//   final String name;
//   final String email;
//   final String location;
//   final int phone;

//   UserData({
//     required this.name,
//     required this.email,
//     required this.location,
//     required this.phone,
//   });
// }

// class Product {
//   final String id;
//   final String name;
//   final double price;
//   final int quantity;
//   final String image;
//   final String description;
//   final String category;

//   Product({
//     required this.id,
//     required this.name,
//     required this.price,
//     required this.quantity,
//     required this.image,
//     required this.description,
//     required this.category,
//   });
// }
