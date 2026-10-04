import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Direct Gmail SMTP service.
/// On native platforms (Android, iOS, Windows, macOS), this sends emails directly
/// to smtp.gmail.com using the Gmail App Password.
/// On Flutter Web (Chrome testing), browser security blocks raw SMTP sockets,
/// so it logs the email and OTP to the debug console for easy testing.
class SmtpService {
  static const String _emailHostUser = 'immadonline702@gmail.com';
  static const String _emailHostPassword = 'cmow ikby ocny giez';

  static Future<bool> sendOTP(String email, String otp) {
    return _send(
      to: email,
      subject: 'Your Verification Code',
      text:
          'Your verification code for MazdoorLink is: $otp\n\n'
          'Please enter this in the app to complete sign up.',
      logLabel: 'Sign Up OTP: $otp',
    );
  }

  static Future<bool> sendPasswordResetOTP(String email, String otp) {
    return _send(
      to: email,
      subject: 'Your MazdoorLink Password Reset Code',
      text:
          'Your MazdoorLink password reset code is: $otp\n\n'
          'Enter this code in the app to continue resetting your password.',
      logLabel: 'Password Reset OTP: $otp',
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
      logLabel: 'Worker Approval for $workerName',
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
      logLabel: 'Worker Rejection for $workerName',
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
      logLabel: 'Schedule Proposal',
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
      logLabel: 'Schedule Confirmed',
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
      logLabel: 'Schedule Declined',
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
      logLabel: 'Arrival Reminder',
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

  static Future<bool> _send({
    required String to,
    required String subject,
    required String text,
    String? logLabel,
  }) async {
    // If running on Flutter Web (Chrome testing), log to console to enable testing
    // because browsers block raw SMTP TCP socket connections.
    if (kIsWeb) {
      print('====================================================');
      print('📧 [WEB DEV EMAIL LOG] To: $to');
      print('Subject: $subject');
      if (logLabel != null) print('Detail: $logLabel');
      print('Body:\n$text');
      print('====================================================');
      return true;
    }

    // Native Mobile / Desktop platform: Send direct via Gmail SMTP server
    try {
      final smtpServer = gmail(_emailHostUser, _emailHostPassword);
      final message = Message()
        ..from = Address(_emailHostUser, 'MazdoorLink')
        ..recipients.add(to)
        ..subject = subject
        ..text = text;

      final sendReport = await send(message, smtpServer);
      print('SMTP Email sent successfully to $to: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('SMTP Email failed to $to: $e');
      return false;
    }
  }
}
