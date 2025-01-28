import 'dart:async';
import 'dart:math';

import 'package:agriplant/models/product.dart';
import 'package:agriplant/services/db_services.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class CartItem extends StatefulWidget {
  const CartItem(
      {super.key,
      required this.cartItem,
      required this.onQuantityChanged,
      required this.onDismissed});

  final Product cartItem;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onDismissed;

  @override
  _CartItemState createState() => _CartItemState();
}

class _CartItemState extends State<CartItem> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.cartItem.quantity ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.cartItem.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.red,
        ),
        child: const Icon(
          IconlyLight.delete,
          color: Colors.white,
          size: 25,
        ),
      ),
      confirmDismiss: (DismissDirection direction) async {
        final completer = Completer<bool>();
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: "Keep",
              onPressed: () {
                completer.complete(false);
                scaffoldMessenger.removeCurrentSnackBar();
              },
            ),
            content: const Text(
              "Remove from cart?",
            ),
          ),
        );
        Timer(const Duration(seconds: 3), () {
          if (!completer.isCompleted) {
            completer.complete(true);
            scaffoldMessenger.removeCurrentSnackBar();
          }
        });

        return await completer.future;
      },
      onDismissed: (direction) async {
        await DBService().deleteProduct(widget.cartItem.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product removed from cart')),
        );
        widget.onDismissed();
      },
      child: SizedBox(
        height: 125,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 0.1,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  height: double.infinity,
                  width: 90,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(widget.cartItem.image),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.cartItem.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        widget.cartItem.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${widget.cartItem.price * quantity} \SDG",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          SizedBox(
                            height: 30,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (quantity > 1) quantity--;
                                      widget.onQuantityChanged(quantity);
                                    });
                                  },
                                  icon: const Icon(Icons.remove),
                                  iconSize: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                  padding: const EdgeInsets.all(0),
                                  constraints: const BoxConstraints(),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    "$quantity",
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      quantity++;
                                      widget.onQuantityChanged(quantity);
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  iconSize: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                  padding: const EdgeInsets.all(0),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
