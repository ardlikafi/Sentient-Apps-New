import 'package:flutter/material.dart';
import 'package:sentient/core/widgets/shimmer_loading.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Shimmer
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 40,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                const ShimmerLoading(width: 110, height: 110, borderRadius: 55),
                const SizedBox(height: 16),
                const ShimmerLoading(width: 150, height: 28),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 200, height: 16),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Subscription Card Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerLoading(width: double.infinity, height: 140, borderRadius: 20),
          ),
          
          const SizedBox(height: 24),
          
          // Menu Sections Shimmer
          _buildMenuSectionShimmer(),
          const SizedBox(height: 24),
          _buildMenuSectionShimmer(),
          const SizedBox(height: 24),
          _buildMenuSectionShimmer(),
        ],
      ),
    );
  }

  Widget _buildMenuSectionShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(width: 120, height: 24),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildMenuItemShimmer(),
                const SizedBox(height: 16),
                _buildMenuItemShimmer(),
                const SizedBox(height: 16),
                _buildMenuItemShimmer(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItemShimmer() {
    return Row(
      children: [
        const ShimmerLoading(width: 40, height: 40, borderRadius: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerLoading(width: 140, height: 16),
              const SizedBox(height: 6),
              const ShimmerLoading(width: 200, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
