import 'dart:io';
import 'package:flutter/foundation.dart'; // Add for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Add for XFile
import 'package:aura_style/core/utils/snackbar_helper.dart';
import 'package:aura_style/core/utils/image_picker_helper.dart';
import 'package:aura_style/core/widgets/primary_button.dart';
import 'package:path_provider/path_provider.dart'; // Add for temp file handling
import 'package:aura_style/features/wardrobe/data/background_removal_service.dart';
import 'package:aura_style/features/wardrobe/data/wardrobe_repository.dart';

final wardrobeRepoProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository();
});

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _brandController = TextEditingController();

  String? _selectedCategory;
  XFile? _selectedImage;
  bool _isLoading = false;

  final List<String> _categories = [
    'Top',
    'Bottom',
    'Dress',
    'Shoes',
    'Accessories',
    'Outerwear',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  bool _isProcessingImage = false;

  Future<void> _pickImage() async {
    final image = await ImagePickerHelper.pickFromGallery();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _removeBackground() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessingImage = true);

    try {
      final service = BackgroundRemovalService();
      final bytes = await service.removeBackground(_selectedImage!);
      
      if (bytes != null) {
        XFile processedImage;
        if (kIsWeb) {
          processedImage = XFile.fromData(bytes, mimeType: 'image/png');
        } else {
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/cutout_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(bytes);
          processedImage = XFile(tempFile.path);
        }

        setState(() {
          _selectedImage = processedImage;
        });
        
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Background removed successfully!');
        }
      }
    } catch (e) {
      // If error is about API key, show helpful message
      if (e.toString().contains('API Key')) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('API Key Missing: Please check background_removal_service.dart'),
               backgroundColor: Colors.orange,
               duration: Duration(seconds: 4),
             ),
           );
         }
      } else {
        if (mounted) {
          SnackbarHelper.showError(context, 'Background removal failed: ${e.toString()}');
        }
      }
    } finally {
       setState(() => _isProcessingImage = false);
    }
  }

  Future<void> _handleAddItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      SnackbarHelper.showError(context, 'Please select a category');
      return;
    }

    if (_selectedImage == null) {
      SnackbarHelper.showError(context, 'Please select an image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(wardrobeRepoProvider);
      await repo.addItem(
        category: _selectedCategory!,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        imageFile: _selectedImage!,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Item added successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: kIsWeb
                                    ? Image.network(
                                        _selectedImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            if (_isProcessingImage)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(height: 12),
                                      Text(
                                        'Removing Background...',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              if (_selectedImage != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Change'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isProcessingImage ? null : _removeBackground,
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: const Text('Remove Background'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
              ),
              const SizedBox(height: 16),

              // Name Field (Optional)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (Optional)',
                  prefixIcon: Icon(Icons.label_outlined),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Color Field (Optional)
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color (Optional)',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Brand Field (Optional)
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand (Optional)',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),

              // Add Button
              PrimaryButton(
                text: 'Add to Wardrobe',
                onPressed: _handleAddItem,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
