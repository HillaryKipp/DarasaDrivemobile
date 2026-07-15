import 'package:flutter/material.dart';
import '../../core/errors/error_handler.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.message,
    this.error,
    this.onRetry,
  });

  final String? message;
  final Object? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final displayMessage = message ?? getErrorMessage(error);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(displayMessage, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
