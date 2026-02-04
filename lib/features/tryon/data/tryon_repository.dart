import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_style/features/tryon/domain/tryon_session.dart';

class TryonRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save a try-on session
  Future<void> saveSession(List<PositionedItem> items) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final outfitData = {
        'items': items.map((item) => item.toJson()).toList(),
      };

      await _supabase.from('tryon_sessions').insert({
        'user_id': userId,
        'outfit_snapshot': outfitData,
      });
    } catch (e) {
      throw Exception('Failed to save session: $e');
    }
  }

  /// Get all sessions for current user
  Future<List<TryonSession>> getMySessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('tryon_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TryonSession.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sessions: $e');
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _supabase.from('tryon_sessions').delete().eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }
}
