import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class NeuralScanPreview extends StatefulWidget {
  final String? imageUrl;
  final bool isGenerating;
  final String label;

  const NeuralScanPreview({
    super.key,
    this.imageUrl,
    required this.isGenerating,
    this.label = 'NEURAL ARCHITECTURE',
  });

  @override
  State<NeuralScanPreview> createState() => _NeuralScanPreviewState();
}

class _NeuralScanPreviewState extends State<NeuralScanPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // BASE IMAGE
          Positioned.fill(
            child: widget.imageUrl != null
                ? Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0D1B26), Color(0xFF050C12)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.amber.withValues(alpha: 0.1),
                        size: 64,
                      ),
                    ),
                  ),
          ),

          // LOADING STATE SHIMMER
          if (widget.isGenerating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.amber),
                ),
              ),
            ),

          // NEURAL SCAN LINE
          if (widget.isGenerating)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return Positioned(
                  top: _scanController.value * 350,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.amber.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // TOP LABEL
          Positioned(
            top: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology_outlined, color: AppColors.amber, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // VOGUE LOGO OVERLAY
          Positioned(
            bottom: 24,
            right: 24,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset('assets/images/logo.png', height: 40),
            ),
          ),
        ],
      ),
    );
  }
}
