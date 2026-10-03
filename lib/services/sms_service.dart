import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SmsService {
  // TextBee device configured from user dashboard
  static const String _defaultDeviceId = '6ac0c343cf8e7692e0f415d6';

  // API Key can be set in .env (TEXTBEE_API_KEY) or fallback placeholder
  static String get _apiKey =>
      dotenv.maybeGet('TEXTBEE_API_KEY') ??
      const String.fromEnvironment('TEXTBEE_API_KEY', defaultValue: '');

  static String get _deviceId =>
      dotenv.maybeGet('TEXTBEE_DEVICE_ID') ?? _defaultDeviceId;

  /// Sends a 4-digit OTP via TextBee SMS Gateway
  static Future<bool> sendOtp(String phoneNumber, String otp) async {
    final formattedNumber = formatPhoneNumber(phoneNumber);
    final message =
        'Your MazdoorLink verification code is: $otp. Valid for 10 minutes.';

    debugPrint('[SmsService] Sending SMS OTP to $formattedNumber: $otp');

    final apiKey = _apiKey;

    // If an API key is provided, send real SMS through TextBee gateway
    if (apiKey.isNotEmpty && apiKey != 'YOUR_FULL_API_KEY') {
      try {
        final url = Uri.parse(
          'https://api.textbee.dev/api/v1/gateway/devices/$_deviceId/send-sms',
        );

        final response = await http.post(
          url,
          headers: {
            'x-api-key': apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'recipients': [formattedNumber], // E.164 format: +923001234567
            'message': message,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('[SmsService] SMS successfully sent via TextBee to $formattedNumber');
          return true;
        } else {
          debugPrint(
            '[SmsService] TextBee SMS failed (${response.statusCode}): ${response.body}',
          );
          // If TextBee returns an error, we return false so the UI knows
          return false;
        }
      } catch (e) {
        debugPrint('[SmsService] Network error sending SMS via TextBee: $e');
        return false;
      }
    } else {
      debugPrint(
        '[SmsService] No TEXTBEE_API_KEY found in .env. Running in simulation mode.',
      );
      // Fallback for simulation / testing when API key is not yet set in .env
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    }
  }

  /// Formats phone number into international E.164 format (e.g. +923038064241)
  static String formatPhoneNumber(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    if (cleaned.startsWith('0')) {
      return '+92${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('92')) {
      return '+$cleaned';
    }
    return '+92$cleaned';
  }
}
