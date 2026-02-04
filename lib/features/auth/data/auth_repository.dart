import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_style/features/auth/domain/user_profile.dart';
import 'package:aura_style/core/constants/supabase_config.dart';
import 'package:aura_style/core/utils/image_picker_helper.dart';
import 'package:image_picker/image_picker.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        throw Exception('Sign up failed. Please try again.');
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('user_profiles')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload user avatar
  Future<String> uploadAvatar(XFile image) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Compress image
      final compressedImage = await ImagePickerHelper.compressImage(image);
      if (compressedImage == null) {
        throw Exception('Failed to compress image');
      }

      // Generate unique filename
      final String fileName = '$userId/avatar.jpg';

      // Upload to storage
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
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }
}
