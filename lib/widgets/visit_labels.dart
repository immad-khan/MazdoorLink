import 'package:flutter/material.dart';

import '../screens/mazdoor_flow.dart' show bilingual;
import '../services/visit_repository.dart';

String formatVisitTime(BuildContext context, DateTime value) {
  final localizations = MaterialLocalizations.of(context);
  final localTime = value.toLocal();
  final day = localizations.formatMediumDate(localTime);
  final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localTime));
  return '$day · $time';
}

String visitErrorMessage(BuildContext context, VisitException error) =>
    switch (error.reason) {
      VisitFailure.signIn => bilingual(
        context,
        'Sign in with an active account to manage visits.',
        'معائنے کے لیے اپنے فعال اکاؤنٹ سے لاگ ان کریں۔',
      ),
      VisitFailure.workerUnavailable => bilingual(
        context,
        'This worker is no longer accepting visits.',
        'یہ ورکر اب معائنے کی درخواستیں نہیں لے رہا۔',
      ),
      VisitFailure.invalidDetails => bilingual(
        context,
        'Check the address, time and note, then try again.',
        'پتہ، وقت اور نوٹ چیک کر کے دوبارہ کوشش کریں۔',
      ),
      VisitFailure.statusChanged => bilingual(
        context,
        'This visit has changed. Check its latest status.',
        'اس درخواست کی حیثیت بدل گئی ہے۔ تازہ صورتحال دیکھیں۔',
      ),
      VisitFailure.timePassed => bilingual(
        context,
        'The requested time has passed.',
        'درخواست میں دیا گیا وقت گزر چکا ہے۔',
      ),
    };
