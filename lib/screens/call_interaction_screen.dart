import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class CallInteractionScreen extends StatefulWidget {
  @override
  State<CallInteractionScreen> createState() => _CallInteractionScreenState();
}

class _CallInteractionScreenState extends State<CallInteractionScreen> {
  bool _speakerOn = false;
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('call_interaction'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.t('call_status_connected'), style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _muted = !_muted),
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                    label: Text(_muted ? t.t('unmute') : t.t('mute')),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _speakerOn = !_speakerOn),
                    icon: Icon(_speakerOn ? Icons.volume_up : Icons.hearing),
                    label: Text(_speakerOn ? t.t('speaker_on') : t.t('speaker_off')),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.t('call_ended'))),
                );
                Navigator.pop(context);
              },
              icon: Icon(Icons.call_end),
              label: Text(t.t('end_call')),
            ),
          ],
        ),
      ),
    );
  }
}
