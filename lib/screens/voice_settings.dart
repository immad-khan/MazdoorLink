import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/speech_service.dart';

class VoiceSettings extends StatefulWidget {
  @override
  _VoiceSettingsState createState() => _VoiceSettingsState();
}

class _VoiceSettingsState extends State<VoiceSettings> {
  bool _voiceEnabled = true;
  final _speechService = SpeechService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('voice_settings'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: _voiceEnabled,
              title: Text(AppLocalizations.of(context).t('enable_speech')),
              onChanged: (v) async {
                setState(() => _voiceEnabled = v);
                if (v) {
                  await _speechService.enableUrduRecognition();
                }
              },
            ),
            SizedBox(height: 12),
            Text(AppLocalizations.of(context).t('record_sample')),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final transcript = await _speechService.captureUrduText();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(transcript)));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context).t('enable_speech_first'))),
                  );
                }
              },
              icon: Icon(Icons.mic),
              label: Text(AppLocalizations.of(context).t('record_sample')),
            ),
            SizedBox(height: 12),
            Text(AppLocalizations.of(context).t('voice_settings_note')),
          ],
        ),
      ),
    );
  }
}
