import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aura_style/core/theme/app_theme.dart';
import 'package:aura_style/features/wardrobe/data/wardrobe_repository.dart';
import 'package:aura_style/features/wardrobe/domain/wardrobe_item.dart';
import 'package:aura_style/features/tryon/data/avatar_generation_service.dart';
import 'package:aura_style/features/auth/application/auth_controller.dart';

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository();
});

final avatarServiceProvider = Provider<AvatarGenerationService>((ref) {
  return AvatarGenerationService();
});

class VirtualTryonCanvas extends ConsumerStatefulWidget {
  const VirtualTryonCanvas({super.key});

  @override
  ConsumerState<VirtualTryonCanvas> createState() =>
      _VirtualTryonCanvasState();
}

class _VirtualTryonCanvasState extends ConsumerState<VirtualTryonCanvas> {
  WardrobeItem? _selectedTop;
  WardrobeItem? _selectedBottom;
  WardrobeItem? _selectedAccessory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Aura Style'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar - Wardrobe
          Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.secondaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'My Wardrobe',
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildWardrobeList(),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/wardrobe/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('ADD ITEM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right Side - 2D Avatar
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.scaffoldBackgroundColor,
                    AppTheme.accentColor.withOpacity(0.1),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 300,
                  height: 500,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.2),
                        AppTheme.secondaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 2D Avatar - Use generated avatar or placeholder
                      _buildAvatarDisplay(),
                      
                      // Selected items overlay
                      if (_selectedTop != null)
                        Positioned(
                          top: 80,
                          child: _buildOverlayItem(_selectedTop!),
                        ),
                      if (_selectedBottom != null)
                        Positioned(
                          top: 200,
                          child: _buildOverlayItem(_selectedBottom!),
                        ),
                      if (_selectedAccessory != null)
                        Positioned(
                          top: 40,
                          child: _buildOverlayItem(_selectedAccessory!, size: 60),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWardrobeList() {
    final wardrobeRepo = ref.watch(wardrobeRepositoryProvider);

    return StreamBuilder<List<WardrobeItem>>(
      stream: wardrobeRepo.getMyItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No items yet.\nAdd clothes to your wardrobe!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final items = snapshot.data!;
        final tops = items.where((i) => i.category.toLowerCase().contains('top') || 
                                         i.category.toLowerCase().contains('shirt') ||
                                         i.category.toLowerCase().contains('blouse')).toList();
        final bottoms = items.where((i) => i.category.toLowerCase().contains('bottom') || 
                                            i.category.toLowerCase().contains('pant') ||
                                            i.category.toLowerCase().contains('skirt') ||
                                            i.category.toLowerCase().contains('jean')).toList();
        final accessories = items.where((i) => i.category.toLowerCase().contains('access')).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (tops.isNotEmpty) _buildCategory('TOPS', tops, 'top'),
            const SizedBox(height: 16),
            if (bottoms.isNotEmpty) _buildCategory('BOTTOMS', bottoms, 'bottom'),
            const SizedBox(height: 16),
            if (accessories.isNotEmpty) _buildCategory('ACCESSORIES', accessories, 'accessory'),
          ],
        );
      },
    );
  }

  Widget _buildCategory(String title, List<WardrobeItem> items, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildWardrobeItem(item, type)),
      ],
    );
  }

  Widget _buildWardrobeItem(WardrobeItem item, String type) {
    final isSelected = (type == 'top' && _selectedTop?.id == item.id) ||
                       (type == 'bottom' && _selectedBottom?.id == item.id) ||
                       (type == 'accessory' && _selectedAccessory?.id == item.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (type == 'top') {
                _selectedTop = isSelected ? null : item;
              } else if (type == 'bottom') {
                _selectedBottom = isSelected ? null : item;
              } else {
                _selectedAccessory = isSelected ? null : item;
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(item.category),
                  size: 16,
                  color: isSelected 
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name ?? 'Unnamed Item',
                    style: TextStyle(
                      color: isSelected 
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayItem(WardrobeItem item, {double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: item.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('shirt') || lower.contains('top') || lower.contains('blouse')) {
      return Icons.checkroom;
    } else if (lower.contains('pant') || lower.contains('jean') || lower.contains('bottom')) {
      return Icons.shop_two;
    } else if (lower.contains('dress')) {
      return Icons.woman;
    } else if (lower.contains('shoe')) {
      return Icons.favorite;
    } else if (lower.contains('access')) {
      return Icons.watch;
    }
    return Icons.shopping_bag_outlined;
  }

  Widget _buildAvatarDisplay() {
    final avatarService = ref.read(avatarServiceProvider);
    final userProfile = ref.watch(currentUserProfileProvider);

    return userProfile.when(
      data: (profile) {
        if (profile == null) {
          return Icon(
            Icons.person,
            size: 180,
            color: AppTheme.primaryColor.withOpacity(0.3),
          );
        }

        // Use DiceBear placeholder avatar (free, no API calls needed)
        final avatarUrl = avatarService.generatePlaceholderAvatar(
          profile.id,
          style: 'avataaars', // Fun, customizable style
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            width: 180,
            height: 180,
            fit: BoxFit.cover,
            placeholder: (context, url) => Icon(
              Icons.person,
              size: 180,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.person,
              size: 180,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
        );
      },
      loading: () => Icon(
        Icons.person,
        size: 180,
        color: AppTheme.primaryColor.withOpacity(0.3),
      ),
      error: (_, __) => Icon(
        Icons.person,
        size: 180,
        color: AppTheme.primaryColor.withOpacity(0.3),
      ),
    );
  }
}
