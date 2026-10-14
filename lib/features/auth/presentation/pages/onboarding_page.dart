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
            title: 'Welcome to Desby',
            description:
                'Keep your orders, clients and measurements in one place. No more notebooks or lost WhatsApp chats.',
            image: 'assets/images/onboarding_image1.webp',
          ),
          const _OnboardingData(
            title: 'Track every order',
            description:
                'See each order move from cutting to stitching to delivery — and let your clients follow along too.',
            image: 'assets/images/onboarding_image2.webp',
          ),
          const _OnboardingData(
            title: 'Show your work. Get customers.',
            description:
                'Publish your designs to the shop and let clients find and book you.',
            image: 'assets/images/onboarding_image3.webp',
          ),
          const _OnboardingData(
            title: 'Learn. Teach. Grow.',
            description:
                'Train apprentices with structured lessons and grow your business with tools that work.',
            image: 'assets/images/onboarding_screens4.webp',
          ),
        ];
      case UserType.apprentice:
        return [
          const _OnboardingData(
            title: 'Learn step by step',
            description:
                'Follow simple lessons from your mentor and watch your progress as you go.',
            image: 'assets/images/tailor.jpg',
          ),
          const _OnboardingData(
            title: 'Practice with real tasks',
            description:
                'Complete tasks from your mentor, get feedback, and build real skills.',
            image: 'assets/images/tailor 1.jpg',
          ),
          const _OnboardingData(
            title: 'Build your portfolio',
            description:
                'Keep every piece you make in one place and see how far you have come.',
            image: 'assets/images/onboarding_image3.webp',
          ),
        ];
      case UserType.fabricSeller:
        return [
          const _OnboardingData(
            title: 'Sell your fabric online',
            description:
                'List your fabrics where tailors and clients are already looking.',
            image:
                'assets/images/african-woman-successful-small-business-fashion marketplace.webp',
          ),
          const _OnboardingData(
            title: 'Know your stock, always',
            description:
                'Track yards, colours and prices in one simple list. No more guesswork.',
            image:
                'assets/images/african-tailor-taking-measurements-client-255059921.webp',
          ),
          const _OnboardingData(
            title: 'Reach more buyers',
            description:
                'Sell beyond your shop counter to wholesale and retail buyers on Desby.',
            image: 'assets/images/onboarding_image3.webp',
          ),
        ];
      case UserType.client:
        return [
          const _OnboardingData(
            title: 'Fashion made just for you',
            description:
                'Find verified tailors near you and book your next outfit in minutes.',
            image:
                'assets/images/two-african-dressmaker-woman-designed-new-red-dress-mannequin-tailor-office-black-seamstress-girls_627829-4465.avif',
          ),
          const _OnboardingData(
            title: 'Follow your order live',
            description:
                'Watch your outfit move from fabric to your front door.',
            image: 'assets/images/onboarding_image2.webp',
          ),
          const _OnboardingData(
            title: 'Get inspired',
            description:
                'Browse real designs from real tailors and find your next look.',
            image: 'assets/images/onboarding_image1.webp',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final userType = UserType.fromString(user?.userType ?? 'tailor');
    final screens = _getScreens(userType);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
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
                      fit: BoxFit.cover,
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
                            colors.scaffoldBg.withValues(alpha: 0.2),
                            colors.scaffoldBg.withValues(alpha: 0.8),
                            colors.scaffoldBg,
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
                        constraints: const BoxConstraints(
                          maxWidth: 800,
                        ), // Responsive desktop centering
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Image.asset('assets/images/logo.webp', height: 80),
                            const SizedBox(height: 40),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: colors.textPrimary,
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
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: colors.textSecondary,
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
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/register', (route) => false),
              child: Text(
                'SKIP',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                        color: _currentIndex == index
                            ? AppColors.amber
                            : colors.textMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                FloatingActionButton.large(
                  onPressed: () {
                    if (_currentIndex == screens.length - 1) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/register', (route) => false);
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  backgroundColor: AppColors.amber,
                  child: Icon(
                    _currentIndex == screens.length - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                    color: context.colors.textOnAmber,
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

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}
