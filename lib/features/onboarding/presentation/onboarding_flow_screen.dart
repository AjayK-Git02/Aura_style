import 'dart:io';
import 'package:flutter/foundation.dart'; // Add for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Add for XFile
import 'package:aura_style/core/theme/app_theme.dart';
import 'package:aura_style/core/utils/snackbar_helper.dart';
import 'package:aura_style/core/utils/image_picker_helper.dart';
import 'package:aura_style/core/widgets/primary_button.dart';
import 'package:aura_style/features/onboarding/data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository();
});

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Step 1: Style Preferences
  final List<String> _availableStyles = [
    'Casual',
    'Formal',
    'Streetwear',
    'Vintage',
    'Bohemian',
    'Minimalist',
    'Sporty',
    'Elegant',
  ];
  final Set<String> _selectedStyles = {};

  // Step 2: Vitals
  String? _selectedGender;
  String? _selectedZodiac;
  DateTime? _selectedBirthDate;
  String? _selectedBodyType;

  final List<String> _zodiacSigns = [
    'Aries',
    'Taurus',
    'Gemini',
    'Cancer',
    'Leo',
    'Virgo',
    'Libra',
    'Scorpio',
    'Sagittarius',
    'Capricorn',
    'Aquarius',
    'Pisces',
  ];

  final List<String> _bodyTypes = [
    'Pear',
    'Apple',
    'Hourglass',
    'Rectangle',
    'Inverted Triangle',
  ];

  // Step 3: Body Photo
  XFile? _bodyPhoto;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleStep1Continue() async {
    if (_selectedStyles.isEmpty) {
      SnackbarHelper.showError(
        context,
        'Please select at least one style preference',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.updateStylePreferences(_selectedStyles.toList());
      _nextPage();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStep2Continue() async {
    if (_selectedGender == null ||
        _selectedZodiac == null ||
        _selectedBirthDate == null ||
        _selectedBodyType == null) {
      SnackbarHelper.showError(
        context,
        'Please complete all fields',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.updateVitals(
        gender: _selectedGender!,
        zodiacSign: _selectedZodiac!,
        birthDate: _selectedBirthDate!,
        bodyType: _selectedBodyType!,
      );
      _nextPage();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStep3Complete() async {
    if (_bodyPhoto == null) {
      SnackbarHelper.showError(
        context,
        'Please upload a full-body photo',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.uploadBodyPhoto(_bodyPhoto!);
      await repo.completeOnboarding();

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'Onboarding completed! Welcome to Aura Style 🎉',
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBodyPhoto() async {
    final image = await ImagePickerHelper.pickFromGallery();
    if (image != null) {
      setState(() {
        _bodyPhoto = image;
      });
    }
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStylePreferencesPage(),
                  _buildVitalsPage(),
                  _buildBodyPhotoPage(),
                ],
              ),
            ),
            
            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _isLoading ? null : _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  PrimaryButton(
                    text: _currentPage == 2 ? 'Finish' : 'Continue',
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_currentPage == 0) _handleStep1Continue();
                            else if (_currentPage == 1) _handleStep2Continue();
                            else _handleStep3Complete();
                          },
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStylePreferencesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your style?',
            style: AppTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Select styles that resonate with you',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableStyles.map((style) {
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
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell Us About You',
            style: AppTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize your experience',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          
          // Gender Selection
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard('Male', Icons.male),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard('Female', Icons.female),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Zodiac Sign
          DropdownButtonFormField<String>(
            initialValue: _selectedZodiac,
            decoration: const InputDecoration(
              labelText: 'Zodiac Sign',
              prefixIcon: Icon(Icons.star_outlined),
            ),
            items: _zodiacSigns.map((zodiac) {
              return DropdownMenuItem(
                value: zodiac,
                child: Text(zodiac),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedZodiac = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Birth Date
          InkWell(
            onTap: _selectBirthDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Birth Date',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _selectedBirthDate != null
                    ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                    : 'Select your birth date',
                style: TextStyle(
                  color: _selectedBirthDate != null
                      ? Colors.black87
                      : Colors.black38,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Body Type
          const Text(
            'Body Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _bodyTypes.map((type) {
              final isSelected = _selectedBodyType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedBodyType = type;
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String gender, IconData icon) {
    final isSelected = _selectedGender == gender.toLowerCase();
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender.toLowerCase();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPhotoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Body Photo',
            style: AppTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This will be used for virtual try-on. Stand straight with arms slightly away from body.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          
          // Photo Preview/Upload Area
          GestureDetector(
            onTap: _pickBodyPhoto,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
                  child: _bodyPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(
                              _bodyPhoto!.path,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_bodyPhoto!.path),
                              fit: BoxFit.cover,
                            ),
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
                          'Tap to upload photo',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          if (_bodyPhoto != null) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _pickBodyPhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('Change Photo'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
