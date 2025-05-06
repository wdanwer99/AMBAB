import 'package:flutter/material.dart';
import 'package:agriplant/models/product.dart';

class SavedProductsPage extends StatefulWidget {
  final List<Product> savedProducts;
  final Future<void> Function(String) deleteProduct;

  const SavedProductsPage({
    super.key,
    required this.savedProducts,
    required this.deleteProduct,
  });

  @override
  _SavedProductsPageState createState() => _SavedProductsPageState();
}

class _SavedProductsPageState extends State<SavedProductsPage> {
  late List<Product> _savedProducts;

  @override
  void initState() {
    super.initState();
    _savedProducts = widget.savedProducts;
  }

  Future<void> deleteSavedProduct(String productId) async {
    await widget.deleteProduct(productId);
    setState(() {
      _savedProducts.removeWhere((product) => product.id == productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Products"),
      ),
      body: ListView.builder(
        itemCount: _savedProducts.length,
        itemBuilder: (context, index) {
          final product = _savedProducts[index];
          return ListTile(
            leading: Image.network(product.image),
            title: Text(product.name),
            subtitle: Text("\$${product.price}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text('Are you sure you want to delete this product?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await deleteSavedProduct(product.id);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
