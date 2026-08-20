import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../theme/colors.dart';

/// Hyper-modern split-screen auth shell with carousel.
/// Left side: white carousel panel. Right side: dark green form panel.
/// On mobile: form only.
class AuthShell extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  static const _slides = [
    _CarouselSlide(
      image: 'assets/images/remote-capturing.png',
      headline: 'Your tailoring\nbusiness, powered\nby AI.',
      accent: 'Manage orders, clients, and designs — all in one place.',
    ),
    _CarouselSlide(
      image: 'assets/images/tailor-full.png',
      headline: 'Where craftsmanship\nmeets innovation.',
      accent: 'Precision tools for the modern artisan.',
    ),
    _CarouselSlide(
      image: 'assets/images/lady-elegant-dress.png',
      headline: 'Effortless elegance,\nperfectly fitted.',
      accent: 'From concept to couture, every stitch tells a story.',
    ),
    _CarouselSlide(
      image: 'assets/images/man-elegant-dress.png',
      headline: 'Royal style,\nprecision tailored.',
      accent: 'Command attention with garments made to measure.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 900) {
            return _buildMobileLayout();
          }
          return _buildDesktopLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Carousel panel (white background)
        Expanded(
          flex: 4,
          child: Container(
            height: double.infinity,
            color: Colors.white,
            child: Stack(
              children: [
                // Carousel
                PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _buildSlide(_slides[i]),
                ),
                // Bottom gradient overlay for text readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 260,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCC0A1921),
                        ],
                      ),
                    ),
                  ),
                ),
                // Text content
                Positioned(
                  left: 48,
                  right: 48,
                  bottom: 48,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      key: ValueKey(_currentPage),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _slides[_currentPage].headline,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _slides[_currentPage].accent,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.amber,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Page indicators
                Positioned(
                  left: 48,
                  bottom: 24,
                  child: Row(
                    children: List.generate(
                      _slides.length,
                      (i) => GestureDetector(
                        onTap: () => _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentPage == i ? 32 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == i
                                ? AppColors.amber
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right: Form panel (dark green background)
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            color: AppColors.darkNavy,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      color: AppColors.darkNavy,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(_CarouselSlide slide) {
    return Container(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image centered with padding
          Padding(
            padding: const EdgeInsets.all(40),
            child: Image.asset(
              slide.image,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselSlide {
  final String image;
  final String headline;
  final String accent;

  const _CarouselSlide({
    required this.image,
    required this.headline,
    required this.accent,
  });
}

/// Logo widget used in auth pages
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 36,
          ),
          const SizedBox(width: 10),
          const Text(
            'Desby',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
