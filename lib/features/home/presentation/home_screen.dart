import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aura_style/core/theme/app_theme.dart';
import 'package:aura_style/features/auth/application/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: Text(
            'Aura Style',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          // Profile Avatar
          userProfile.when(
            data: (profile) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                    image: profile?.avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(profile!.avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profile?.avatarUrl == null
                      ? const Icon(Icons.person, color: AppTheme.primaryColor, size: 20)
                      : null,
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212), // Deep Charcoal
              Color(0xFF1E1E1E), // Lighter Charcoal
            ],
          ),
        ),
        child: userProfile.when(
          data: (profile) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Text(
                    'Hello,',
                    style: AppTheme.headlineMedium.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ), 
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile?.fullName ?? "Fashionista",
                    style: AppTheme.headlineLarge.copyWith(
                      fontSize: 36, // Make name larger for hierarchy
                    ),
                  ),
                  const SizedBox(height: 16), // Increased spacing for elegance
                  Text(
                    'Curate your elegance.',
                    style: GoogleFonts.lato(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      letterSpacing: 1.5, // Spaced out for premium feel
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 56), // More breathing room before cards

                  // Feature Cards
                  _buildFeatureCard(
                    context,
                    title: 'My Wardrobe',
                    description: 'Manage your collection',
                    icon: Icons.checkroom,
                    // Gold/Black Gradient
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => context.push('/wardrobe'),
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    title: 'Virtual Try-On',
                    description: 'Visualize your look',
                    icon: Icons.face_retouching_natural,
                    // Platinum/Dark Gradient
                    gradient: const LinearGradient(
                      colors: [Color(0xFF383838), Color(0xFF252525)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => context.push('/tryon'),
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context,
                    title: 'Style Quiz',
                    description: 'Discover your essence',
                    icon: Icons.auto_awesome,
                    // Bronze/Dark Gradient
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () => context.push('/quiz'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          error: (error, stack) => Center(
            child: Text('Error loading profile: $error', style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.lato(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.2),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
