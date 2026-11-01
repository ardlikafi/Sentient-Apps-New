import 'package:flutter/material.dart';
import 'package:sentient/core/widgets/shimmer_loading.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Shimmer
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 40,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShimmerLoading(width: 120, height: 20),
                      const SizedBox(height: 8),
                      const ShimmerLoading(width: 180, height: 28),
                    ],
                  ),
                ),
                const ShimmerLoading(width: 50, height: 50, borderRadius: 25),
              ],
            ),
          ),
          
          // Carousel Shimmer
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerLoading(
              width: double.infinity,
              height: 180,
              borderRadius: 20,
            ),
          ),
          
          // Courses Section Shimmer
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerLoading(width: 150, height: 24),
                const ShimmerLoading(width: 60, height: 16),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 260,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ShimmerLoading(width: 160, height: 260, borderRadius: 20),
                );
              },
            ),
          ),
          
          // Shop Section Shimmer
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ShimmerLoading(width: 150, height: 24),
                const ShimmerLoading(width: 60, height: 16),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 240,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ShimmerLoading(width: 160, height: 240, borderRadius: 20),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
