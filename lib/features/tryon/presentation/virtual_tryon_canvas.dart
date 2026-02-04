import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_style/core/constants/supabase_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:aura_style/core/theme/app_theme.dart';
import 'package:aura_style/core/utils/snackbar_helper.dart';
import 'package:aura_style/features/auth/application/auth_controller.dart';
import 'package:aura_style/features/wardrobe/data/wardrobe_repository.dart';
import 'package:aura_style/features/wardrobe/domain/wardrobe_item.dart';
import 'package:aura_style/features/tryon/data/tryon_repository.dart';
import 'package:aura_style/features/tryon/domain/tryon_session.dart';

final tryonRepositoryProvider = Provider<TryonRepository>((ref) {
  return TryonRepository();
});

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository();
});

class VirtualTryonCanvas extends ConsumerStatefulWidget {
  const VirtualTryonCanvas({super.key});

  @override
  ConsumerState<VirtualTryonCanvas> createState() =>
      _VirtualTryonCanvasState();
}

class _VirtualTryonCanvasState extends ConsumerState<VirtualTryonCanvas> {
  final List<_DraggableClothingItem> _placedItems = [];
  bool _isLoading = false;
  String? _bodyPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadBodyPhoto();
  }

  Future<void> _loadBodyPhoto() async {
    final profile = await ref.read(currentUserProfileProvider.future);
    if (profile == null) return;
    
    // Check if we need to use a signed URL (if bucket is private)
    // We construct the path since we know it's always 'userId/body.jpg'
    final path = '${profile.id}/body.jpg';
    
    try {
      final signedUrl = await Supabase.instance.client
          .storage
          .from(SupabaseConfig.userMediaBucket)
          .createSignedUrl(path, 3600); // 1 hour expiry
          
      setState(() {
        _bodyPhotoUrl = signedUrl;
      });
    } catch (e) {
      // Fallback to the stored URL if signing fails (e.g. if it's already a public URL or different path)
      setState(() {
        _bodyPhotoUrl = profile.tryonBodyPhotoUrl;
      });
    }
  }

  void _addItem(WardrobeItem item) {
    setState(() {
      _placedItems.add(_DraggableClothingItem(
        item: item,
        position: Offset(100, _placedItems.length * 50.0 + 100),
        scale: 0.5,
      ));
    });
    Navigator.pop(context); // Close bottom sheet
  }

  void _updateItemPosition(int index, Offset newPosition) {
    setState(() {
      _placedItems[index] = _placedItems[index].copyWith(position: newPosition);
    });
  }

  void _updateItemScale(int index, double newScale) {
    setState(() {
      _placedItems[index] = _placedItems[index].copyWith(scale: newScale);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _placedItems.removeAt(index);
    });
  }

  Future<void> _saveSession() async {
    if (_placedItems.isEmpty) {
      SnackbarHelper.showError(
        context,
        'Add some items to your outfit first!',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final positionedItems = _placedItems.map((item) {
        return PositionedItem(
          itemId: item.item.id,
          x: item.position.dx,
          y: item.position.dy,
          scale: item.scale,
        );
      }).toList();

      final repo = ref.read(tryonRepositoryProvider);
      await repo.saveSession(positionedItems);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Outfit saved successfully! 🎉',
        );
        setState(() {
          _placedItems.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showWardrobeDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WardrobeDrawer(onItemSelected: _addItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Try-On'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSession,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background: Body Photo
          if (_bodyPhotoUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: _bodyPhotoUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.person_outline, size: 80),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.grey.shade100,
                child: const Center(
                  child: Text(
                    'Upload a body photo in settings\nto use virtual try-on',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
            ),

          // Draggable Clothing Items
          ..._placedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Positioned(
              left: item.position.dx,
              top: item.position.dy,
              child: Draggable(
                feedback: _buildClothingWidget(item, isDragging: true),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  _updateItemPosition(index, details.offset);
                },
                child: GestureDetector(
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Item Options'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.zoom_in),
                              title: const Text('Make Bigger'),
                              onTap: () {
                                _updateItemScale(index, item.scale + 0.1);
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.zoom_out),
                              title: const Text('Make Smaller'),
                              onTap: () {
                                _updateItemScale(
                                  index,
                                  (item.scale - 0.1).clamp(0.1, 2.0),
                                );
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Remove'),
                              onTap: () {
                                _removeItem(index);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: _buildClothingWidget(item),
                ),
              ),
            );
          }),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showWardrobeDrawer,
        icon: const Icon(Icons.checkroom),
        label: const Text('Add Clothes'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildClothingWidget(_DraggableClothingItem item,
      {bool isDragging = false}) {
    return Container(
      width: 100 * item.scale,
      height: 100 * item.scale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (!isDragging)
           BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: item.item.imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _DraggableClothingItem {
  final WardrobeItem item;
  final Offset position;
  final double scale;

  _DraggableClothingItem({
    required this.item,
    required this.position,
    required this.scale,
  });

  _DraggableClothingItem copyWith({
    WardrobeItem? item,
    Offset? position,
    double? scale,
  }) {
    return _DraggableClothingItem(
      item: item ?? this.item,
      position: position ?? this.position,
      scale: scale ?? this.scale,
    );
  }
}

class _WardrobeDrawer extends ConsumerWidget {
  final Function(WardrobeItem) onItemSelected;

  const _WardrobeDrawer({required this.onItemSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeRepo = ref.watch(wardrobeRepositoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Virtual Try-On',
              style: AppTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<WardrobeItem>>(
              stream: wardrobeRepo.getMyItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No items in wardrobe'),
                  );
                }

                final items = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => onItemSelected(item),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
