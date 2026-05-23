import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class JobNotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('job_notifications'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.t('new_job_request'), style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Text('${t.t('category')}: ${t.t('plumbing')}'),
                Text('${t.t('distance')}: 2.1 km'),
                Text('${t.t('budget')}: Rs 1800 - Rs 2200'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.t('job_accepted'))),
                          );
                        },
                        child: Text(t.t('accept')),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.t('job_rejected'))),
                          );
                        },
                        child: Text(t.t('reject')),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
