import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class TranslationToggleScreen extends StatefulWidget {
  @override
  State<TranslationToggleScreen> createState() => _TranslationToggleScreenState();
}

class _TranslationToggleScreenState extends State<TranslationToggleScreen> {
  bool _enabled = true;
  String _direction = 'en_to_ur';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('translation_toggle'))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: Text(t.t('enable_translation')),
          ),
          SizedBox(height: 12),
          Text(t.t('translation_direction')),
          RadioListTile<String>(
            value: 'en_to_ur',
            groupValue: _direction,
            onChanged: (v) => setState(() => _direction = v ?? _direction),
            title: Text(t.t('en_to_ur')),
          ),
          RadioListTile<String>(
            value: 'ur_to_en',
            groupValue: _direction,
            onChanged: (v) => setState(() => _direction = v ?? _direction),
            title: Text(t.t('ur_to_en')),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.t('translation_settings_saved'))),
              );
            },
            child: Text(t.t('save_preferences')),
          ),
        ],
      ),
    );
  }
}
