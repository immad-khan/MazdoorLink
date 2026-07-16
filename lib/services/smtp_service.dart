import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SmtpService {
  static const String _emailHost = 'smtp.gmail.com';
  static const int _emailPort = 587;
  static const String _emailHostUser = 'immadonline702@gmail.com';
  static const String _emailHostPassword = 'ivcj icxn jpnl ekbo';
  static const String _emailFromName = 'Mazdoorlink';

  static Future<bool> sendOTP(String email, String otp) async {
    final smtpServer = SmtpServer(
      _emailHost,
      port: _emailPort,
      username: _emailHostUser,
      password: _emailHostPassword,
    );

    final message = Message()
      ..from = Address(_emailHostUser, _emailFromName)
      ..recipients.add(email)
      ..subject = 'Your Verification Code'
      ..text =
          'Your verification code for MazdoorLink is: $otp. Please enter this in the app to complete sign up.';

    try {
      await send(message, smtpServer);
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
