import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service for generating 2D/3D avatars from user photos using Ready Player Me API.
/// Ready Player Me is free and perfect for fashion/virtual try-on apps.
class AvatarGenerationService {
  // Ready Player Me API endpoints
  static const String _baseUrl = 'https://api.readyplayer.me';
  static const String _avatarApiUrl = '$_baseUrl/v1/avatars';
  
  /// Generates a 2D avatar from a user's photo.
  /// Returns the avatar URL that can be used to display the avatar.
  /// 
  /// The avatar can be customized with different body types, poses, and clothing.
  Future<String?> generateAvatarFromPhoto(XFile photoFile) async {
    try {
      // Step 1: Upload the photo to Ready Player Me
      final uploadUrl = await _uploadPhoto(photoFile);
      if (uploadUrl == null) {
        throw Exception('Failed to upload photo');
      }

      // Step 2: Create avatar from the uploaded photo
      final avatarUrl = await _createAvatar(uploadUrl);
      
      return avatarUrl;
    } catch (e) {
      debugPrint('Error generating avatar: $e');
      rethrow;
    }
  }

  /// Uploads photo to Ready Player Me and returns the upload URL
  Future<String?> _uploadPhoto(XFile photoFile) async {
    try {
      final bytes = await photoFile.readAsBytes();
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_avatarApiUrl/from-photo'),
      );
      
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: 'user_photo.jpg',
      ));

      request.fields.addAll({
        'type': 'halfbody', // Options: fullbody, halfbody
        'gender': 'auto', // Auto-detect gender
      });

      final response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['data']['url'] as String?;
      } else {
        debugPrint('Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      return null;
    }
  }

  /// Creates avatar from uploaded photo URL
  Future<String?> _createAvatar(String photoUrl) async {
    try {
      final response = await http.post(
        Uri.parse(_avatarApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'photoUrl': photoUrl,
          'bodyType': 'halfbody',
          'gender': 'auto',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        
        // Extract avatar URL (can be GLB or PNG)
        final avatarUrl = jsonData['data']['avatarUrl'] as String?;
        
        // For 2D representation, append render parameters
        if (avatarUrl != null) {
          return '$avatarUrl?scene=fullbody-portrait-v1&format=png';
        }
        return avatarUrl;
      } else {
        debugPrint('Avatar creation failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating avatar: $e');
      return null;
    }
  }

  /// Alternative: Generate avatar from simple parameters (no photo needed)
  /// Useful for quick demos or when users don't want to upload photos
  Future<String?> generateAvatarFromParameters({
    String? gender,
    String? bodyType = 'halfbody',
    String? skinTone,
  }) async {
    try {
      // This creates a random avatar based on parameters
      final url = Uri.parse('$_baseUrl/v1/avatars/templates');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'bodyType': bodyType,
          'gender': gender ?? 'auto',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final avatarId = jsonData['data']['id'] as String?;
        
        if (avatarId != null) {
          // Return render URL
          return '$_baseUrl/v1/avatars/$avatarId.png?scene=fullbody-portrait-v1';
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error generating avatar: $e');
      return null;
    }
  }

  /// Get avatar as 2D PNG render
  /// You can customize pose, scene, and quality
  String getAvatarRenderUrl(
    String avatarId, {
    String scene = 'fullbody-portrait-v1',
    String pose = 'T',
    int quality = 1024,
  }) {
    return '$_baseUrl/v1/avatars/$avatarId.png?scene=$scene&pose=$pose&quality=$quality';
  }

  /// Alternative FREE option: Use DiceBear for placeholder avatars
  /// This doesn't require photos but creates styled avatars from seed
  String generatePlaceholderAvatar(String userId, {String style = 'avataaars'}) {
    // DiceBear API - completely free
    // Styles: avataaars, bottts, personas, pixel-art, etc.
    return 'https://api.dicebear.com/7.x/$style/svg?seed=$userId';
  }
}
