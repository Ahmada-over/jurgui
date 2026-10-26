import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/colors.dart';

class ErrorRetryCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  const ErrorRetryCard({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.circleAlert,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 15),
              label: const Text(
                'Réessayer',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );

    if (compact) return content;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: content,
        ),
      ),
    );
  }
}
