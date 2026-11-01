import 'package:flutter/material.dart';
import 'package:sentient/core/widgets/shimmer_loading.dart';

class ShopShimmer extends StatelessWidget {
  const ShopShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Shimmer
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: ShimmerLoading(width: 80, height: 40, borderRadius: 20),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Grid Shimmer
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return const ShimmerLoading(width: double.infinity, height: double.infinity, borderRadius: 20);
            },
          ),
        ],
      ),
    );
  }
}
