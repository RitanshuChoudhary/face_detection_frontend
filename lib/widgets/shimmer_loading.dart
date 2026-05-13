import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/constants.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppConstants.cardColorDark
            : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          const ShimmerPlaceholder(
            width: 48,
            height: 48,
            borderRadius: 24, // Circular
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerPlaceholder(width: 140, height: 16),
                SizedBox(height: 8),
                ShimmerPlaceholder(width: 200, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const ShimmerPlaceholder(width: 24, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

class ShimmerCardSkeleton extends StatelessWidget {
  const ShimmerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppConstants.cardColorDark
            : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerPlaceholder(width: 120, height: 18),
              ShimmerPlaceholder(width: 80, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerPlaceholder(width: 180, height: 13),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: const [
              ShimmerPlaceholder(width: 24, height: 24, borderRadius: 12),
              SizedBox(width: 8),
              ShimmerPlaceholder(width: 100, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class ShimmerGridSkeleton extends StatelessWidget {
  const ShimmerGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppConstants.cardColorDark
            : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10
              : Colors.black.withOpacity(0.04),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          ShimmerPlaceholder(width: 32, height: 32, borderRadius: 16),
          SizedBox(height: 16),
          ShimmerPlaceholder(width: 80, height: 14),
        ],
      ),
    );
  }
}
