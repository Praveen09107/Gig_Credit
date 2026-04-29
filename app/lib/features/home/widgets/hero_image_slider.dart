import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class HeroImageSlider extends StatefulWidget {
  const HeroImageSlider({super.key});

  @override
  State<HeroImageSlider> createState() => _HeroImageSliderState();
}

class _HeroImageSliderState extends State<HeroImageSlider> {
  final PageController _controller = PageController(viewportFraction: 0.85);

  final List<String> _images = [
    'assets/images/gig_delivery.jpeg',
    'assets/images/gig_plumber.jpeg',
    'assets/images/gig_electrician.jpeg',
    'assets/images/gig_construction.jpeg',
  ];

  final List<String> _captions = [
    'Delivery Partners',
    'Skilled Tradespeople',
    'Electricians & Technicians',
    'Construction Workers',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Empowering India\'s Gig Workers',
          style: AppTypography.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Building financial inclusion for 300M+ informal workers across India.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double value = 1.0;
                  if (_controller.position.haveDimensions) {
                    value = _controller.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 220,
                      width: Curves.easeOut.transform(value) * 350,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage(_images[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    alignment: Alignment.bottomLeft,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _captions[index],
                      style: AppTypography.titleMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
