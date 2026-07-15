import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SmtpService {
  static Future<bool> sendOTP(String email, String otp) async {
    // Replace with real SMTP credentials
    String username = 'your_email@gmail.com';
    String password = 'your_app_password';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'MazdoorLink')
      ..recipients.add(email)
      ..subject = 'Your Verification Code'
      ..text = 'Your verification code for MazdoorLink is: $otp. Please enter this in the app to complete sign up.';

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
