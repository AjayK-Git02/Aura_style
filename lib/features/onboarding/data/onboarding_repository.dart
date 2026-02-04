import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Add for XFile
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_style/core/constants/supabase_config.dart';
import 'package:aura_style/core/utils/image_picker_helper.dart';

class OnboardingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Update style preferences
  Future<void> updateStylePreferences(List<String> styles) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('user_profiles').update({
        'style_preferences': styles,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update style preferences: $e');
    }
  }

  /// Update vitals (gender, zodiac, birth date, body type)
  Future<void> updateVitals({
    required String gender,
    required String zodiacSign,
    required DateTime birthDate,
    required String bodyType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('user_profiles').update({
        'gender': gender,
        'zodiac_sign': zodiacSign,
        'birth_date': birthDate.toIso8601String().split('T')[0],
        'body_type': bodyType,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update vitals: $e');
    }
  }

  /// Upload body photo for virtual try-on
  Future<String> uploadBodyPhoto(XFile image) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Compress image (will skip on web)
      final compressedImage = await ImagePickerHelper.compressImage(image);
      if (compressedImage == null) {
        throw Exception('Failed to compress image');
      }

      // Generate unique filename
      final String fileName = '$userId/body.jpg';

      // Upload to storage
      // Use uploadBinary to support both Web and Mobile
      final bytes = await compressedImage.readAsBytes();
      await _supabase.storage.from(SupabaseConfig.userMediaBucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(SupabaseConfig.userMediaBucket)
          .getPublicUrl(fileName);

      // Update profile with photo URL
      await _supabase.from('user_profiles').update({
        'tryon_body_photo_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload body photo: $e');
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('user_profiles').update({
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to complete onboarding: $e');
    }
  }
}
