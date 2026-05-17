import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Skeleton Shimmer Loader (Level 2E)
/// Used for lists / cards while content is loading.
/// ─────────────────────────────────────────────────────────────────────────────
class SkeletonShimmer extends StatelessWidget {
  final bool isList;

  const SkeletonShimmer({
    super.key,
    this.isList = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isList) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => _buildCardSkeleton(),
      );
    }
    return _buildCardSkeleton();
  }

  Widget _buildCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EDE7)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 120, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 80, height: 12, borderRadius: 4),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _ShimmerBox(width: double.infinity, height: 48, borderRadius: 12),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color(0xFFF0F4F8),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1400.ms,
          color: const Color(0xFFE2EDE7),
          colors: [
            const Color(0xFFF0F4F8),
            const Color(0xFFE2EDE7),
            const Color(0xFFF0F4F8),
          ],
          stops: const [0.0, 0.4, 0.8],
          angle: 0, // 90deg sweep left to right
          size: 2, // 200% background size
        );
  }
}
