import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class BackgroundRemovalService {
  // TODO: Replace with your actual API key from remove.bg or similar service
  static const String _apiKey = 'kizrwgcTxLF9YJqCJPK45YFV';
  static const String _apiUrl = 'https://api.remove.bg/v1.0/removebg';

  /// Removes background from the given image file.
  /// Returns the processed image bytes.
  Future<Uint8List?> removeBackground(XFile imageFile) async {
    try {
      if (_apiKey == 'YOUR_API_KEY_HERE') {
        debugPrint('⚠️ No API Key found for Background Removal.');
        // For demo purposes, we'll return null to indicate we can't process it,
        // or you could return the original bytes if you prefer (but that defeats the purpose).
        // Let's throw specific error to handle in UI.
        throw Exception('API Key not configured');
      }

      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers.addAll({'X-Api-Key': _apiKey});
      
      // Add image file
      // Note: On web we might need readAsBytes, on mobile path. 
      // XFile abstraction helps here but MultipartFile.fromPath is standard.
      // For web compatibility with XFile, using fromBytes is safer if we read it first.
      
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'image_file', 
        bytes,
        filename: 'image.jpg', // Generic name
      ));
      
      request.fields.addAll({
        'size': 'auto',
      });

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        return responseData;
      } else {
        final respStr = await response.stream.bytesToString();
        debugPrint('Failed to remove background: $respStr');
        throw Exception('Failed to remove background: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error removing background: $e');
      rethrow;
    }
  }
}
