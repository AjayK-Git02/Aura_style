import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aura_style/core/theme/app_theme.dart';
import 'package:aura_style/features/auth/application/auth_controller.dart';
import 'package:aura_style/core/widgets/primary_button.dart';
import 'package:aura_style/core/utils/image_picker_helper.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  
  // Edit State
  String? _selectedGender;
  String? _selectedZodiac;
  String? _selectedBodyType;
  List<String> _selectedStyles = [];

  final List<String> _zodiacSigns = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  final List<String> _bodyTypes = [
    'Pear', 'Apple', 'Hourglass', 'Rectangle', 'Inverted Triangle'
  ];

  final List<String> _allStyles = [
    'Casual', 'Formal', 'Streetwear', 'Vintage', 
    'Bohemian', 'Minimalist', 'Sporty', 'Elegant',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    final profile = ref.read(currentUserProfileProvider).value;
    if (!_isEditing && profile != null) {
      _nameController.text = profile.fullName ?? '';
      _selectedGender = profile.gender;
      _selectedZodiac = profile.zodiacSign;
      _selectedBodyType = profile.bodyType;
      _selectedStyles = List.from(profile.stylePreferences);
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            fullName: newName,
            gender: _selectedGender,
            zodiacSign: _selectedZodiac,
            bodyType: _selectedBodyType,
            stylePreferences: _selectedStyles,
          );
      
      setState(() {
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePickerHelper.pickFromGallery();
    if (image != null) {
      try {
        await ref.read(authControllerProvider.notifier).uploadAvatar(image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading avatar: $e')),
          );
        }
      }
    }
  }

  String _getAvatarAsset(String? gender) {
    if (gender == 'male') {
      return 'assets/images/avatar_boy.png'; // Placeholder path
    } else {
      return 'assets/images/avatar_girl.png'; // Placeholder path
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _isEditing ? _saveProfile : _toggleEdit,
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('User not found'));

          // Determine avatar
          final avatarUrl = profile.avatarUrl;
          final gender = profile.gender;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 58,
                          backgroundColor: AppTheme.surfaceColor,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Icon(
                                  gender == 'male' ? Icons.face : Icons.face_3,
                                  size: 60,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                      ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                if (_isEditing)
                  TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.headlineMedium,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      border: UnderlineInputBorder(),
                    ),
                  )
                else
                  Text(
                    profile.fullName ?? 'No Name',
                    style: AppTheme.lightTheme.textTheme.headlineMedium,
                  ),

                const SizedBox(height: 8),
                Text(
                  profile.email,
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 48),

                const SizedBox(height: 32),

                // Editable Fields
                if (_isEditing) ...[
                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: ['male', 'female', 'other'].map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                  const SizedBox(height: 16),
                  
                  // Zodiac Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedZodiac,
                    decoration: const InputDecoration(
                      labelText: 'Zodiac Sign',
                      prefixIcon: Icon(Icons.star),
                    ),
                    items: _zodiacSigns.map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedZodiac = val),
                  ),
                  const SizedBox(height: 16),
                  
                  // Body Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedBodyType,
                    decoration: const InputDecoration(
                      labelText: 'Body Type',
                      prefixIcon: Icon(Icons.accessibility_new),
                    ),
                    items: _bodyTypes.map((String val) {
                      return DropdownMenuItem(value: val, child: Text(val));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBodyType = val),
                  ),
                  const SizedBox(height: 24),
                  
                  // Style Preferences Editor
                  const Text('Style Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allStyles.map((style) {
                      final isSelected = _selectedStyles.contains(style);
                      return FilterChip(
                        label: Text(style),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStyles.add(style);
                            } else {
                              _selectedStyles.remove(style);
                            }
                          });
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        checkmarkColor: AppTheme.primaryColor,
                      );
                    }).toList(),
                  ),
                ] else ...[
                  // Static View (Existing Info Cards)
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Zodiac',
                          profile.zodiacSign ?? '-',
                          Icons.star,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Body Type',
                          profile.bodyType ?? '-',
                          Icons.accessibility_new,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Style Preferences (Static)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.style, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Style Preferences',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.stylePreferences.map((style) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                style,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Sign Out',
                  isOutlined: true,
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
