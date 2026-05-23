import 'package:flutter/material.dart';
import '../error/error_handler.dart';

mixin AsyncHandler {
  /// Execute an async operation with automatic error handling
  Future<T?> handleAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? successMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      final result = await operation();

      if (showLoading && context.mounted) {
        Navigator.pop(context);
      }

      if (successMessage != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
        );
      }

      return result;
    } catch (e) {
      if (showLoading && context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        final failure = ErrorHandler.mapExceptionToFailure(e);
        final message = ErrorHandler.getUserMessage(failure);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }
}
