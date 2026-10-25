import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SafepaySession {
  final String trackerToken;
  final String tbt;
  final String checkoutUrl;

  const SafepaySession({
    required this.trackerToken,
    required this.tbt,
    required this.checkoutUrl,
  });
}

class SafepayService {
  static final SafepayService instance = SafepayService._();
  SafepayService._();

  static const String _defaultPublicKey = 'sec_e96433cd-885d-416c-8e23-eb34e150e7f3';
  static const String _defaultSecretKey = '135c485e2696fe4f024e68aa4bd011f605ec99282cd8f47c39135e1962162837';

  String get publicKey => dotenv.env['SAFEPAY_PUBLIC_KEY']?.trim() ?? _defaultPublicKey;
  String get secretKey => dotenv.env['SAFEPAY_SECRET_KEY']?.trim() ?? _defaultSecretKey;
  bool get isSandbox => (dotenv.env['SAFEPAY_ENV'] ?? 'sandbox').toLowerCase() != 'production';

  String get baseUrl => isSandbox
      ? 'https://sandbox.api.getsafepay.com'
      : 'https://api.getsafepay.com';

  /// Step 1: Generates a short-lived client/passport token (TBT).
  Future<String> createPassportToken() async {
    final response = await http.post(
      Uri.parse('$baseUrl/client/passport/v1/token'),
      headers: {
        'X-SFPY-MERCHANT-SECRET': secretKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final token = json['data']?.toString() ?? '';
      if (token.isNotEmpty) return token;
    }
    throw Exception('Failed to generate Safepay passport token: ${response.body}');
  }

  /// Step 2: Creates an order payment tracker session and constructs checkout URL.
  Future<SafepaySession> createCheckoutSession({
    required double amountInPkr,
    required String orderId,
    String? redirectUrl,
    String? cancelUrl,
  }) async {
    // 1. Get passport token (tbt)
    final tbt = await createPassportToken();

    // Amount in lowest currency denomination (Paisa for PKR: 1 PKR = 100 Paisas)
    final amountInPaisa = (amountInPkr * 100).round();

    // 2. Create payment tracker
    final payload = {
      'merchant_api_key': publicKey,
      'intent': 'CYBERSOURCE',
      'mode': 'payment',
      'currency': 'PKR',
      'amount': amountInPaisa,
      'metadata': {
        'order_id': orderId,
      },
      if (redirectUrl != null) 'redirect_url': redirectUrl,
      if (cancelUrl != null) 'cancel_url': cancelUrl,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/order/payments/v3/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final trackerData = json['data']?['tracker'];
      String trackerToken = '';
      if (trackerData is Map) {
        trackerToken = trackerData['token']?.toString() ?? '';
      } else if (json['data']?['token'] != null) {
        trackerToken = json['data']['token'].toString();
      }

      if (trackerToken.isEmpty) {
        throw Exception('Could not extract tracker token from response: ${response.body}');
      }

      final env = isSandbox ? 'sandbox' : 'production';
      final checkoutUrl = '$baseUrl/components?beacon=$trackerToken&tbt=$tbt&environment=$env&source=mobile';

      return SafepaySession(
        trackerToken: trackerToken,
        tbt: tbt,
        checkoutUrl: checkoutUrl,
      );
    }

    throw Exception('Failed to create Safepay payment session: ${response.body}');
  }

  /// Step 3: Verifies whether the payment session has completed (TRACKER_ENDED).
  Future<bool> verifyPayment(String trackerToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reporter/api/v1/payments/$trackerToken'),
        headers: {
          'X-SFPY-MERCHANT-SECRET': secretKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final state = json['data']?['state']?.toString();
        return state == 'TRACKER_ENDED';
      }
    } catch (_) {}
    return false;
  }

  /// Launches checkout in in-app browser view or external browser.
  Future<bool> launchCheckout(String checkoutUrl) async {
    final uri = Uri.parse(checkoutUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
    return false;
  }

  /// Starts the end-to-end payment flow:
  /// 1. Creates checkout session
  /// 2. Launches browser checkout
  /// 3. Opens verification bottom sheet with test card details and verification button
  Future<void> startPaymentFlow({
    required BuildContext context,
    required double amount,
    required String orderId,
    required String title,
    required Future<void> Function() onPaymentSuccess,
  }) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF0D9488)),
                SizedBox(height: 16),
                Text('Connecting to Safepay Sandbox...', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

    SafepaySession? session;
    try {
      session = await createCheckoutSession(
        amountInPkr: amount,
        orderId: orderId,
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Safepay Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // Dismiss loading dialog
    if (context.mounted) Navigator.pop(context);

    // Launch checkout URL
    await launchCheckout(session.checkoutUrl);

    // Show verification sheet
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _SafepayVerificationSheet(
        session: session!,
        amount: amount,
        title: title,
        onVerified: () async {
          Navigator.pop(sheetCtx);
          await onPaymentSuccess();
        },
      ),
    );
  }
}

class _SafepayVerificationSheet extends StatefulWidget {
  final SafepaySession session;
  final double amount;
  final String title;
  final Future<void> Function() onVerified;

  const _SafepayVerificationSheet({
    required this.session,
    required this.amount,
    required this.title,
    required this.onVerified,
  });

  @override
  State<_SafepayVerificationSheet> createState() => _SafepayVerificationSheetState();
}

class _SafepayVerificationSheetState extends State<_SafepayVerificationSheet> {
  bool _isChecking = false;
  String? _statusMessage;

  Future<void> _checkPayment({bool simulate = false}) async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    if (simulate) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _isChecking = false);
      await widget.onVerified();
      return;
    }

    try {
      final isPaid = await SafepayService.instance.verifyPayment(widget.session.trackerToken);
      if (!mounted) return;
      setState(() => _isChecking = false);

      if (isPaid) {
        await widget.onVerified();
      } else {
        setState(() {
          _statusMessage = 'Payment pending. Complete the transaction in your browser, then tap Verify again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _statusMessage = 'Error checking status: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Safepay Sandbox Checkout', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Text('SANDBOX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Payable:', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text(
                      'Rs. ${widget.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Row(
                  children: [
                    Icon(Icons.open_in_browser, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Checkout opened in your browser.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF16A34A)),
                    SizedBox(width: 6),
                    Text('Safepay Sandbox Test Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                  ],
                ),
                SizedBox(height: 4),
                Text('• Card: 4111 1111 1111 1111', style: TextStyle(fontSize: 12, color: Color(0xFF15803D))),
                Text('• Exp: 12/28 | CVV: 123 | OTP: 123456', style: TextStyle(fontSize: 12, color: Color(0xFF15803D))),
              ],
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isChecking ? null : () => _checkPayment(simulate: false),
            icon: _isChecking
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: Text(_isChecking ? 'Verifying with Safepay...' : 'I Have Paid — Verify Payment'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => SafepayService.instance.launchCheckout(widget.session.checkoutUrl),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Re-open Checkout', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: _isChecking ? null : () => _checkPayment(simulate: true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Simulate Success', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
