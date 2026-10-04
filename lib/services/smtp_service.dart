import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends emails via the Firebase Cloud Function `sendEmail`.
/// This works on Flutter Web (and mobile) because it uses an HTTP call
/// instead of raw SMTP sockets (which browsers block).
class SmtpService {
  // Firebase Cloud Functions base URL for the mazdoorlink-30879 project.
  // Region: us-central1 (default)
  static const String _functionUrl =
      'https://us-central1-mazdoorlink-30879.cloudfunctions.net/sendEmail';

  static Future<bool> sendOTP(String email, String otp) {
    return _send(
      to: email,
      subject: 'Your Verification Code',
      text:
          'Your verification code for MazdoorLink is: $otp\n\n'
          'Please enter this in the app to complete sign up.',
    );
  }

  static Future<bool> sendPasswordResetOTP(String email, String otp) {
    return _send(
      to: email,
      subject: 'Your MazdoorLink Password Reset Code',
      text:
          'Your MazdoorLink password reset code is: $otp\n\n'
          'Enter this code in the app to continue resetting your password.',
    );
  }

  static Future<bool> sendWorkerApprovalEmail({
    required String email,
    required String workerName,
  }) {
    return _send(
      to: email,
      subject: 'Your MazdoorLink worker account has been approved',
      text:
          'Hello $workerName,\n\n'
          'Your MazdoorLink worker account has been approved. '
          'You may now log in with your credentials and start using your worker dashboard.\n\n'
          'Thank you,\nMazdoorLink',
    );
  }

  static Future<bool> sendWorkerRejectionEmail({
    required String email,
    required String workerName,
    required String reason,
  }) {
    return _send(
      to: email,
      subject: 'Your MazdoorLink worker registration was rejected',
      text:
          'Hello $workerName,\n\n'
          'Your MazdoorLink worker registration was rejected by admin.\n\n'
          'Reason:\n$reason\n\n'
          'Please review the issue and contact support or sign up again with corrected details.\n\n'
          'Thank you,\nMazdoorLink',
    );
  }

  static Future<bool> sendScheduleProposalEmail({
    required String email,
    required String workerName,
    required String jobDesc,
    required DateTime scheduledTime,
  }) {
    return _send(
      to: email,
      subject: 'Worker proposed a schedule for your MazdoorLink job',
      text:
          'Hello,\n\n'
          '$workerName is busy with another job and has proposed to arrive at '
          '${_formatTime(scheduledTime)} for your request: "$jobDesc".\n\n'
          'Please open the MazdoorLink app to Approve or Decline this schedule.\n\n'
          'Thank you,\nMazdoorLink',
    );
  }

  static Future<bool> sendScheduleConfirmedEmail({
    required String email,
    required String workerName,
    required String jobDesc,
    required DateTime scheduledTime,
  }) {
    return _send(
      to: email,
      subject: 'Customer confirmed your proposed schedule',
      text:
          'Hello $workerName,\n\n'
          'Your customer approved your proposed arrival time of '
          '${_formatTime(scheduledTime)} for the job: "$jobDesc".\n\n'
          'Open the MazdoorLink app at that time to start the job.\n\n'
          'Thank you,\nMazdoorLink',
    );
  }

  static Future<bool> sendScheduleDeclinedEmail({
    required String email,
    required String workerName,
    required String jobDesc,
  }) {
    return _send(
      to: email,
      subject: 'Customer declined your proposed schedule',
      text:
          'Hello $workerName,\n\n'
          'Your customer declined the proposed schedule for the job: "$jobDesc".\n\n'
          'The job has been closed.\n\n'
          'Thank you,\nMazdoorLink',
    );
  }

  static Future<bool> sendArrivalReminderEmail({
    required String email,
    required String jobDesc,
  }) {
    return _send(
      to: email,
      subject: 'Reminder: your scheduled MazdoorLink job time has arrived',
      text:
          'Hello,\n\n'
          'The scheduled time for your MazdoorLink job "$jobDesc" has arrived. '
          'The worker should be arriving now.\n\n'
          'Thank you,\nMazdoorLink',
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    final day =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    return '$day at $hour:${local.minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Calls the Firebase Cloud Function to send an email.
  /// The function URL uses the v2 callable format (POST with JSON body).
  static Future<bool> _send({
    required String to,
    required String subject,
    required String text,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'data': {'to': to, 'subject': subject, 'text': text},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final result = body['result'] as Map<String, dynamic>?;
        return result?['success'] == true;
      } else {
        print('sendEmail HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('sendEmail error: $e');
      return false;
    }
  }
}
