import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class OnboardingScaffold extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String stepLabel;
  final String prompt;
  final Widget content;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool isLoading;
  final String nextLabel;

  const OnboardingScaffold({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.stepLabel,
    required this.prompt,
    required this.content,
    this.onBack,
    this.onNext,
    this.isLoading = false,
    this.nextLabel = 'CONTINUE',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentStep == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Progress?'),
            content: const Text('All progress in this setup wizard will be lost.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('KEEP EDITING')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DISCARD', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: Stack(
          children: [
            // 1. Ambient Background System
            _buildAmbientBackground(),
            
            // 2. Main Scrollable Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        // Header Identity & Progress
                        _buildHeader(),
                        const SizedBox(height: 56),
                        
                        // Main Heading
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48, // Calibrated for mobile/tablet
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Content Card
                        _buildMainCard(),
                        
                        const SizedBox(height: 120), // Space for footer
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // 3. Footer Navigation
            _buildFooter(),
            
            // 4. Floating Support
            _buildFloatingSupport(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return Stack(
      children: [
        // Bottom Center Glow
        Positioned(
          bottom: -100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 600,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ),
        // Secondary Glow
        Positioned(
          top: 100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber.withValues(alpha: 0.05),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 24),
            const SizedBox(width: 10),
            const Text(
              'DESBY OS',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Progress System
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.amber : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 56),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Text(
                stepLabel.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 48),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkNavy.withValues(alpha: 0),
              AppColors.darkNavy.withValues(alpha: 0.9),
              AppColors.darkNavy,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: () {
                    // WEB STABILITY: Aggressive focus purge
                    FocusManager.instance.primaryFocus?.unfocus();
                    Future.delayed(const Duration(milliseconds: 150), onBack);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              if (onBack != null) const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    onPressed: isLoading || onNext == null ? null : () {
                      // WEB STABILITY: Aggressive focus purge
                      FocusManager.instance.primaryFocus?.unfocus();
                      Future.delayed(const Duration(milliseconds: 150), onNext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.darkNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.darkNavy),
                          )
                        : Text(
                            nextLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSupport() {
    return Positioned(
      bottom: 120,
      right: 24,
      child: Stack(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 24),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkNavy, width: 2),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.amber : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ] : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? AppColors.darkNavy : Colors.white70,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
