import 'package:flutter/material.dart';
import '../../theme/colors.dart';

enum OnboardingUserType { apprentice, tailor, client, fabricSeller }

class OnboardingShell extends StatelessWidget {
  final OnboardingUserType userType;
  final int currentStep;
  final int totalSteps;
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool isLoading;
  final String nextLabel;

  const OnboardingShell({
    super.key,
    required this.userType,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.child,
    this.onBack,
    this.onNext,
    this.isLoading = false,
    this.nextLabel = 'CONTINUE',
  });

  String get _headline => 'Your tailoring\njourney starts here.';
  String get _accent => 'Where craftsmanship meets innovation.';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 900) {
            return _buildMobileLayout(context, colors);
          }
          return _buildDesktopLayout(context, colors);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, DesbyThemeColors colors) {
    return Row(
      children: [
        // Left: Image panel — single static image
        Expanded(
          flex: 4,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/desby-onboarding.jpg',
                  fit: BoxFit.cover,
                ),
                // Bottom gradient for text readability
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
                        colors: [Colors.transparent, Color(0xCC0A1921)],
                      ),
                    ),
                  ),
                ),
                // Headline text
                Positioned(
                  left: 48,
                  right: 48,
                  bottom: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _headline,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                          letterSpacing: -1.2,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _accent,
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
                // Step indicators
                Positioned(
                  left: 48,
                  bottom: 24,
                  child: Row(
                    children: List.generate(
                      totalSteps,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: i == currentStep ? 32 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i <= currentStep
                              ? AppColors.amber
                              : colors.divider,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right: Form panel
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            color: colors.scaffoldBg,
            child: Column(
              children: [
                // Scrollable content area
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(colors),
                            const SizedBox(height: 32),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 32),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Fixed footer with buttons
                _buildFooter(context, colors),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, DesbyThemeColors colors) {
    return Container(
      color: colors.scaffoldBg,
      child: Column(
        children: [
          // Mobile header with progress
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _buildHeader(colors),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: child,
            ),
          ),
          // Fixed footer
          _buildFooter(context, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(DesbyThemeColors colors) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 24),
            const SizedBox(width: 10),
            Text(
              'DESBY OS',
              style: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Progress bar
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.amber : colors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, DesbyThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.scaffoldBg.withValues(alpha: 0), colors.scaffoldBg],
        ),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
                Future.delayed(const Duration(milliseconds: 300), onBack!);
              },
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white54,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colors.borderSubtle,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          if (onBack != null) const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: isLoading || onNext == null
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        FocusManager.instance.primaryFocus?.unfocus();
                        Future.delayed(
                          const Duration(milliseconds: 300),
                          onNext!,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.darkNavy,
                        ),
                      )
                    : Text(
                        nextLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OptionPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber : colors.borderSubtle,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.amber : colors.borderDefault,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? AppColors.darkNavy : colors.textSecondary,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
