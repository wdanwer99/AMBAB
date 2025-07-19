import 'package:agriplant/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

import 'order_product.dart';

class OrderItemWidget extends StatelessWidget {
  const OrderItemWidget({super.key, required this.order, this.visibleProducts = 2});

  final Order order;
  final int visibleProducts;

  @override
  Widget build(BuildContext context) {
    final products = order.items.take(visibleProducts).toList();
    final totalPrice = order.items
        .fold(0.0, (previousValue, element) => previousValue + element.total);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Order: ${order.id}",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "(${order.items.length} Items)",
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 5),
                Text(
                  "\$${totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...List.generate(products.length, (index) {
              final item = products[index];
              return _buildOrderItemWidget(item);
            }),
            if (order.items.length > 1) const SizedBox(height: 10),
            if (order.items.length > 1)
              Center(
                  child: TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (context) {
                      return Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.background,
                        ),
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: order.items.length,
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            return _buildOrderItemWidget(item);
                          },
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(IconlyBold.arrowRight),
                label: const Text("View all"),
              ))
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemWidget(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            width: 60,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(item.productImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '\$${item.total.toStringAsFixed(2)}',
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
  }
}
