import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message, this.textColor});

  final String? message;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            if (message != null) ...[
              const SizedBox(height: 20),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor ?? const Color(0xFF1E293B), // Darker text for readability
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
