import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService._();

  static const String _cloudName = 'dcdhsyj86';
  static const String _apiKey = '921185953673167';
  static const String _apiSecret = 'P-Vro4fA8_gF9dnTcHgKnOQ-xGI';

  static Future<String?> uploadImage(File imageFile) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final strToSign = "timestamp=$timestamp$_apiSecret";
    final bytes = utf8.encode(strToSign);
    final digest = sha1.convert(bytes);
    final signature = digest.toString();

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['api_key'] = _apiKey;
    request.fields['timestamp'] = timestamp.toString();
    request.fields['signature'] = signature;
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonMap = json.decode(responseData);
      return jsonMap['secure_url'];
    }
    return null;
  }
}
