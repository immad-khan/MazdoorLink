import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class EarningsDashboard extends StatelessWidget {
  final double totalToday;
  EarningsDashboard({required this.totalToday});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).t('earnings'), style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text('${AppLocalizations.of(context).t('today')}: Rs ${totalToday.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.history), SizedBox(width: 8), Text(AppLocalizations.of(context).t('historical_earnings'))])
          ],
        ),
      ),
    );
  }
}
