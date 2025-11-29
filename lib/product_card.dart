import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'liked_products_provider.dart';
import 'product_detail_screen.dart';

const Color kPrimaryBlue = Color(0xFF0F52BA);
const Color kDarkBlue = Color(0xFF000A26);
const Color kLightBlue = Color(0xFFA6C6D8);
const Color kVeryLightBlue = Color(0xFFD6E5F2);

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.decimalPattern('id_ID');

    return Consumer<LikedProductsProvider>(
      builder: (context, likedProvider, child) {
        final bool isLiked = likedProvider.isLiked(product['id']!);

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product))),
          child: Container(
            decoration: BoxDecoration(color: kPrimaryBlue, borderRadius: BorderRadius.circular(15.0), boxShadow: [BoxShadow(color: kDarkBlue.withOpacity(0.15), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(15.0), topRight: Radius.circular(15.0)), child: Image.asset(product['imageUrl']!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: kLightBlue.withOpacity(0.3), child: Center(child: Icon(Icons.broken_image_outlined, color: kVeryLightBlue.withOpacity(0.7), size: 40)))))),
                Flexible(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(product['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kVeryLightBlue), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(product['subtitle'] ?? 'Item', style: TextStyle(fontSize: 11, color: kVeryLightBlue.withOpacity(0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("Rp. ${formatCurrency.format(product['price'])}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            InkWell(
                              onTap: () => likedProvider.toggleLike(product['id']!),
                              customBorder: const CircleBorder(),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(color: kVeryLightBlue.withOpacity(0.2), shape: BoxShape.circle),
                                child: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.redAccent : kVeryLightBlue,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}