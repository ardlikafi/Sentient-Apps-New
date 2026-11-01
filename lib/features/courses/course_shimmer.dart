import 'package:flutter/material.dart';
import 'package:sentient/core/widgets/shimmer_loading.dart';

class CourseListShimmer extends StatelessWidget {
  const CourseListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const ShimmerLoading(width: 80, height: 80, borderRadius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoading(width: 180, height: 16),
                    const SizedBox(height: 8),
                    const ShimmerLoading(width: 120, height: 12),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const ShimmerLoading(width: 60, height: 20, borderRadius: 10),
                        const SizedBox(width: 8),
                        const ShimmerLoading(width: 60, height: 20, borderRadius: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
