import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'liked_products_provider.dart';
import 'product_card.dart';
import 'mock_data.dart';

class LikedProductsScreen extends StatelessWidget {
  const LikedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVeryLightBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kDarkBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Wishlist',
          style: TextStyle(color: kDarkBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Consumer<LikedProductsProvider>(
        builder: (context, likedProvider, child) {
          final likedProducts = allMockProducts.where((product) {
            return likedProvider.isLiked(product['id']!);
          }).toList();

          if (likedProducts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 100, color: Colors.grey),
                  SizedBox(height: 24),
                  Text('No Liked Products Yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kDarkBlue)),
                  SizedBox(height: 8),
                  Text('Tap the heart on any product\nto add it to your wishlist.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.72,
            ),
            itemCount: likedProducts.length,
            itemBuilder: (context, index) {
              return ProductCard(product: likedProducts[index]);
            },
          );
        },
      ),
    );
  }
}