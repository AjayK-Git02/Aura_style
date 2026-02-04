import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Add for XFile
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_style/core/constants/supabase_config.dart';
import 'package:aura_style/core/utils/image_picker_helper.dart';
import 'package:aura_style/features/wardrobe/domain/wardrobe_item.dart';
import 'package:uuid/uuid.dart';

class WardrobeRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a new wardrobe item
  Future<void> addItem({
    required String category,
    String? name,
    String? color,
    String? brand,
    required XFile imageFile,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Compress image
      final compressedImage = await ImagePickerHelper.compressImage(imageFile);
      if (compressedImage == null) {
        throw Exception('Failed to compress image');
      }

      // Generate unique filename
      final String fileName = '${const Uuid().v4()}.jpg';

      // Upload to storage
      final bytes = await compressedImage.readAsBytes();
      await _supabase.storage
          .from(SupabaseConfig.wardrobeImagesBucket)
          .uploadBinary(fileName, bytes);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from(SupabaseConfig.wardrobeImagesBucket)
          .getPublicUrl(fileName);

      // Insert into database
      await _supabase.from('wardrobe_items').insert({
        'user_id': userId,
        'name': name,
        'category': category,
        'color': color,
        'brand': brand,
        'image_url': publicUrl,
      });
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  /// Get all wardrobe items for current user
  Stream<List<WardrobeItem>> getMyItems() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('wardrobe_items')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((json) => WardrobeItem.fromJson(json)).toList();
        });
  }

  /// Delete a wardrobe item
  Future<void> deleteItem(String itemId) async {
    try {
      await _supabase.from('wardrobe_items').delete().eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Get items by category
  Future<List<WardrobeItem>> getItemsByCategory(String category) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('wardrobe_items')
          .select()
          .eq('user_id', userId)
          .eq('category', category)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WardrobeItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch items: $e');
    }
  }
}
