import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class LanguageSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('language_selection'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context).t('language_urdu')),
              onTap: () => Navigator.pop(context, Locale('ur')),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context).t('language_english')),
              onTap: () => Navigator.pop(context, Locale('en')),
            ),
          ],
        ),
      ),
    );
  }
}
