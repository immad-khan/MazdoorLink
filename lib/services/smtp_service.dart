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
