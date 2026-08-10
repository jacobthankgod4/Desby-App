import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String moduleName;

  const ErrorBoundary({
    super.key, 
    required this.child, 
    this.moduleName = 'MODULE',
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 24),
                Text(
                  '${widget.moduleName.toUpperCase()} CRITICAL FAULT',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    _errorDetails!.exception.toString(),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white24, fontSize: 9, fontFamily: 'Courier'),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _errorDetails = null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.darkNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('RECOVER COMPONENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ErrorWidgetBuilder(
      onError: (details) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorDetails = details;
            });
          }
        });
      },
      child: widget.child,
    );
  }
}

class ErrorWidgetBuilder extends StatelessWidget {
  final Widget child;
  final Function(FlutterErrorDetails) onError;

  const ErrorWidgetBuilder({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final oldBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      onError(details);
      return const SizedBox.shrink();
    };
    
    // We must restore the builder after build
    // But since this is a widget, it's tricky.
    // Better to use a more local approach.

    return child;
  }
}
