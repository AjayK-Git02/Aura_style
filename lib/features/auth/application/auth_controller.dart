import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aura_style/features/auth/data/auth_repository.dart';
import 'package:aura_style/features/auth/domain/user_profile.dart';
import 'package:image_picker/image_picker.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Current User Profile Provider
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final authRepo = ref.watch(authRepositoryProvider);
  
  await for (final authState in authRepo.authStateChanges) {
    if (authState.session != null) {
      final profile = await authRepo.getCurrentUserProfile();
      yield profile;
    } else {
      yield null;
    }
  }
});

// Auth Controller
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 SignIn attempt for: $email');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signIn(email: email, password: password);
      debugPrint('✅ SignIn successful');
    });
    
    if (state.hasError) {
      debugPrint('❌ SignIn error: ${state.error}');
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
    });
  }

  Future<void> updateProfile({
    String? fullName,
    String? gender,
    String? zodiacSign,
    String? bodyType,
    List<String>? stylePreferences,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updates = <String, dynamic>{};
      
      if (fullName != null) updates['full_name'] = fullName;
      if (gender != null) updates['gender'] = gender;
      if (zodiacSign != null) updates['zodiac_sign'] = zodiacSign;
      if (bodyType != null) updates['body_type'] = bodyType;
      if (stylePreferences != null) updates['style_preferences'] = stylePreferences;
      
      if (updates.isNotEmpty) {
        await _authRepository.updateProfile(updates);
      }
    });
  }

  Future<void> uploadAvatar(XFile image) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
       await _authRepository.uploadAvatar(image);
       // The stream provider will automatically emit the new profile with updated avatar
    });
  }
}

// Auth Controller Provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthController(authRepo);
});
