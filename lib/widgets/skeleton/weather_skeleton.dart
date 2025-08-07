import 'package:flutter/material.dart';

/// A skeleton loading widget for weather details
///
/// This widget shows a placeholder UI while the actual weather data is loading,
/// providing a better user experience than a simple progress indicator.
class WeatherSkeleton extends StatelessWidget {
  final bool isWideScreen;

  const WeatherSkeleton({
    super.key,
    this.isWideScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCurrentWeatherSkeleton(context),
          const SizedBox(height: 16),
          _buildForecastSkeleton(context),
          if (!isWideScreen) const SizedBox(height: 16),
          if (!isWideScreen) _buildWarningsSkeleton(context),
          const SizedBox(height: 16),
          _buildObservationsSkeleton(context),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherSkeleton(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location dropdown skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonBox(context, width: 150, height: 24),
                _buildSkeletonBox(context, width: 40, height: 24),
              ],
            ),
            const SizedBox(height: 24),

            // Temperature and weather icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSkeletonBox(context, width: 120, height: 80),
                _buildSkeletonCircle(context, size: 80),
              ],
            ),
            const SizedBox(height: 24),

            // Weather details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSkeletonBox(context, width: 80, height: 60),
                _buildSkeletonBox(context, width: 80, height: 60),
                _buildSkeletonBox(context, width: 80, height: 60),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSkeleton(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonBox(context, width: 100, height: 24),
            const SizedBox(height: 16),

            // Hourly forecast
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSkeletonBox(context, width: 40, height: 16),
                        _buildSkeletonCircle(context, size: 40),
                        _buildSkeletonBox(context, width: 30, height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Daily forecast
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSkeletonBox(context, width: 80, height: 16),
                      _buildSkeletonCircle(context, size: 30),
                      _buildSkeletonBox(context, width: 60, height: 16),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsSkeleton(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonBox(context, width: 120, height: 24),
            const SizedBox(height: 16),

            // Warning items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _buildSkeletonCircle(context, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSkeletonBox(context, height: 16),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsSkeleton(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonBox(context, width: 120, height: 24),
            const SizedBox(height: 16),

            // Chart skeleton
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a skeleton box with a pulsing animation
  Widget _buildSkeletonBox(BuildContext context,
      {double? width, required double height}) {
    return _SkeletonAnimation(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Creates a skeleton circle with a pulsing animation
  Widget _buildSkeletonCircle(BuildContext context, {required double size}) {
    return _SkeletonAnimation(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A widget that applies a pulsing animation to its child
class _SkeletonAnimation extends StatefulWidget {
  final Widget child;

  const _SkeletonAnimation({required this.child});

  @override
  State<_SkeletonAnimation> createState() => _SkeletonAnimationState();
}

class _SkeletonAnimationState extends State<_SkeletonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
