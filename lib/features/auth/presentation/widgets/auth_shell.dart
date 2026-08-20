import 'package:flutter/material.dart';

import '../../../../theme/colors.dart';

/// Korra-style split-screen auth shell.
/// Left side: visual panel with headline. Right side: form.
/// On mobile: form only (side panel hidden).
class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String headline;
  final String headlineAccent;
  final Widget child;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.headline,
    required this.headlineAccent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          if (!isWide) {
            return _buildMobileLayout(context);
          }
          return _buildDesktopLayout(context);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left: Visual panel
        Expanded(
          flex: 4,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1921),
                  Color(0xFF102A35),
                  Color(0xFF1B3022),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -80,
                  left: -80,
                  child: _decorativeCircle(200, AppColors.amber.withOpacity(0.08)),
                ),
                Positioned(
                  bottom: -120,
                  right: -60,
                  child: _decorativeCircle(300, AppColors.amber.withOpacity(0.05)),
                ),
                Positioned(
                  top: 200,
                  right: 100,
                  child: _decorativeCircle(120, AppColors.accent.withOpacity(0.06)),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        headlineAccent,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amber,
                        ),
                      ),
                    ],
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
            color: Colors.black,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
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
