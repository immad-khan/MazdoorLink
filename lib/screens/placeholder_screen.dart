import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../app_theme.dart';

class FeatureInfoScreen extends StatelessWidget {
  final String title;
  final String description;

  const FeatureInfoScreen({super.key, required this.title, required this. description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    child: const Icon(Icons.info_outline, color: Color(0xFF0D9488)),
                  ),
                  const SizedBox(height: 14),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 14),
                  Text(
                    AppLocalizations.of(context).t('service_platform'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.deactivatedText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
