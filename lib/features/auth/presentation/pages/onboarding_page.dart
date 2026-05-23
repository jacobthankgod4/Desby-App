import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/colors.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/user_types.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<_OnboardingData> _getScreens(UserType type) {
    switch (type) {
      case UserType.tailor:
        return [
          const _OnboardingData(
            title: 'Precision in Every Stitch',
            description: 'The digital companion for master tailors. Manage your craftsmanship with atomic precision.',
            image: 'assets/images/onboarding image1.png',
          ),
          const _OnboardingData(
            title: 'Seamless Order Flow',
            description: 'From measurements to final fitting. Track every stage of your client\'s journey without missing a single detail.',
            image: 'assets/images/onboarding image2.png',
          ),
          const _OnboardingData(
            title: 'Design Your Empire',
            description: 'Your portfolio, your marketplace, your growth. Desby OS scales your fashion business.',
            image: 'assets/images/onboarding image3.png',
            zoomOut: true,
          ),
          const _OnboardingData(
            title: 'Connect & Collaborate',
            description: 'Join a network of elite designers. Share inspiration and grow your brand globally.',
            image: 'assets/images/onboarding screens4.png',
          ),
        ];
      case UserType.apprentice:
        return [
          const _OnboardingData(
            title: 'Master the Craft',
            description: 'Learn from the best. Track your learning modules and skill progress in real-time.',
            image: 'assets/images/tailor.jpg',
          ),
          const _OnboardingData(
            title: 'Earn While Learning',
            description: 'Complete assigned tasks and earn incentives as you grow your fashion expertise.',
            image: 'assets/images/tailor 1.jpg',
          ),
          const _OnboardingData(
            title: 'Your Future Portfolio',
            description: 'Build a body of work that showcases your journey from beginner to master artisan.',
            image: 'assets/images/onboarding image3.png',
            zoomOut: true,
          ),
        ];
      case UserType.fabricSeller:
        return [
          const _OnboardingData(
            title: 'Market Your Fabrics',
            description: 'Showcase your premium stock to a network of elite tailors and designers.',
            image: 'assets/images/african-woman-successful-small-business-fashion marketplace.webp',
          ),
          const _OnboardingData(
            title: 'Inventory at a Glance',
            description: 'Manage your yardage, colors, and textures with ease. Never lose track of your stock.',
            image: 'assets/images/african-tailor-taking-measurements-client-255059921.webp',
          ),
          const _OnboardingData(
            title: 'Grow Your Sales',
            description: 'Connect directly with high-volume buyers. Expand your reach beyond your physical shop.',
            image: 'assets/images/onboarding image3.png',
            zoomOut: true,
          ),
        ];
      case UserType.client:
        return [
          const _OnboardingData(
            title: 'Bespoke Luxury',
            description: 'Experience fashion tailored exclusively for you. Book the world\'s best artisans.',
            image: 'assets/images/two-african-dressmaker-woman-designed-new-red-dress-mannequin-tailor-office-black-seamstress-girls_627829-4465.avif',
          ),
          const _OnboardingData(
            title: 'Track Your Fit',
            description: 'Monitor your garment creation in real-time. Know exactly when your masterpiece is ready.',
            image: 'assets/images/onboarding image2.png',
          ),
          const _OnboardingData(
            title: 'Style Inspiration',
            description: 'Browse thousands of unique designs and find the perfect match for your next occasion.',
            image: 'assets/images/onboarding image1.png',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userType = UserType.fromString(user?.userType ?? 'tailor');
    final screens = _getScreens(userType);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: screens.length,
            itemBuilder: (context, index) {
              final data = screens[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      data.image,
                      fit: data.zoomOut ? BoxFit.contain : BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.darkNavy.withValues(alpha: 0.2),
                            AppColors.darkNavy.withValues(alpha: 0.8),
                            AppColors.darkNavy,
                          ],
                          stops: const [0.0, 0.6, 0.9],
                        ),
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800), // Responsive desktop centering
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Image.asset('assets/images/logo.png', height: 80),
                            const SizedBox(height: 40),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                data.title,
                                key: ValueKey<String>(data.title),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              child: Text(
                                data.description,
                                key: ValueKey<String>(data.description),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          Positioned(
            top: 60,
            right: 20,
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/register', (route) => false),
              child: const Text('SKIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    screens.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentIndex == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? AppColors.amber : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                FloatingActionButton.large(
                  onPressed: () {
                    if (_currentIndex == screens.length - 1) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/register', (route) => false);
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  backgroundColor: AppColors.amber,
                  child: Icon(
                    _currentIndex == screens.length - 1 ? Icons.check : Icons.arrow_forward,
                    color: AppColors.darkNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final String image;
  final bool zoomOut;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    this.zoomOut = false,
  });
}
