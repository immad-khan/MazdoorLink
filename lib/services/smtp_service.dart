import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SmtpService {
  static const String _emailHost = 'smtp.gmail.com';
  static const int _emailPort = 587;
  static const String _emailHostUser = 'immadonline702@gmail.com';
  static const String _emailHostPassword = 'ivcj icxn jpnl ekbo';
  static const String _emailFromName = 'Mazdoorlink';

  static SmtpServer get _smtpServer => SmtpServer(
        _emailHost,
        port: _emailPort,
        username: _emailHostUser,
        password: _emailHostPassword,
      );

  static Future<bool> sendOTP(String email, String otp) async {
    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Your Verification Code'
      ..text =
          'Your verification code for MazdoorLink is: $otp. Please enter this in the app to complete sign up.';

    return _sendMessage(message);
  }

  static Future<bool> sendPasswordResetOTP(String email, String otp) async {
    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Your MazdoorLink Password Reset Code'
      ..text =
          'Your MazdoorLink password reset code is: $otp. Enter this code in the app to continue resetting your password.';

    return _sendMessage(message);
  }

  static Future<bool> sendWorkerApprovalEmail({
    required String email,
    required String workerName,
  }) async {
    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Your MazdoorLink worker account has been approved'
      ..text =
          'Hello $workerName,\n\nYour MazdoorLink worker account has been approved. You may now log in with your credentials and start using your worker dashboard.\n\nThank you,\nMazdoorLink';

    return _sendMessage(message);
  }

  static Future<bool> sendWorkerRejectionEmail({
    required String email,
    required String workerName,
    required String reason,
  }) async {
    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Your MazdoorLink worker registration was rejected'
      ..text =
          'Hello $workerName,\n\nYour MazdoorLink worker registration was rejected by admin.\n\nReason:\n$reason\n\nPlease review the issue and contact support or sign up again with corrected details.\n\nThank you,\nMazdoorLink';

    return _sendMessage(message);
  }

  static Future<bool> sendScheduleProposalEmail({
    required String email,
    required String workerName,
    required String jobDesc,
    required DateTime scheduledTime,
  }) async {
    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Worker proposed a schedule for your MazdoorLink job'
      ..text =
          'Hello,\n\n$workerName is busy with another job and has proposed to arrive at ${_formatTime(scheduledTime)} for your request: "$jobDesc".\n\nPlease open the MazdoorLink app to Approve or Decline this schedule.\n\nThank you,\nMazdoorLink';

    return _sendMessage(message);
  }

  static Future<bool> sendScheduleConfirmedEmail({
    required String email,
    required String workerName,
    required String jobDesc,
    required DateTime scheduledTime,
  }) async {
    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Customer confirmed your proposed schedule'
      ..text =
          'Hello $workerName,\n\nYour customer approved your proposed arrival time of ${_formatTime(scheduledTime)} for the job: "$jobDesc".\n\nOpen the MazdoorLink app at that time to start the job.\n\nThank you,\nMazdoorLink';

    return _sendMessage(message);
  }

  static Future<bool> sendScheduleDeclinedEmail({
    required String email,
    required String workerName,
    required String jobDesc,
  }) async {
    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Customer declined your proposed schedule'
      ..text =
          'Hello $workerName,\n\nYour customer declined the proposed schedule for the job: "$jobDesc".\n\nThe job has been closed.\n\nThank you,\nMazdoorLink';

    return _sendMessage(message);
  }

  static Future<bool> sendArrivalReminderEmail({
    required String email,
    required String jobDesc,
  }) async {
    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Reminder: your scheduled MazdoorLink job time has arrived'
      ..text =
          'Hello,\n\nThe scheduled time for your MazdoorLink job "$jobDesc" has arrived. The worker should be arriving now.\n\nThank you,\nMazdoorLink';

    return _sendMessage(message);
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    final day = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    return '$day at $hour:${local.minute.toString().padLeft(2, '0')} $amPm';
  }

  static Future<bool> _sendMessage(Message message) async {
    try {
      await send(message, _smtpServer);
      return true;
    } on MailerException catch (e) {
      print('Message not sent. \n${e.message}');
      return false;
    } catch (e) {
      print('SMTP Error: $e');
      return false;
    }
  }
}
