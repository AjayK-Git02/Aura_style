import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_style/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  
  // "A" Animations
  late Animation<double> _aScale;
  late Animation<double> _aOpacity;
  late Animation<Offset> _aSlide;

  // "URA" Animations
  late Animation<Offset> _uraSlide;
  late Animation<double> _uraOpacity;

  // "STYLE" Animations
  late Animation<double> _styleOpacity;
  late Animation<double> _styleSpacing;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // 1. "A" enters big and scales down (0.0 - 1.2s)
    _aOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _aScale = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOutExpo)),
    );
    // Slide "A" slightly left to make room (1.0 - 1.8s)
    _aSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.1, 0)).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.5, curve: Curves.easeInOutCubic)),
    );

    // 2. "URA" slides out from behind A (1.0 - 1.8s)
    _uraSlide = Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.5, curve: Curves.easeInOutCubic)),
    );
    _uraOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.9, 1.6, curve: Curves.easeOut)),
    );

    // 3. "STYLE" fades in with expanding spacing (1.8 - 2.8s)
    _styleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(1.8, 2.5, curve: Curves.easeIn)),
    );
    _styleSpacing = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(1.8, 3.0, curve: Curves.easeOutQuart)),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 4000), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
       try {
          final profile = await Supabase.instance.client
              .from('user_profiles')
              .select('onboarding_completed')
              .eq('id', session.user.id)
              .single();
          
          final completed = profile['onboarding_completed'] as bool? ?? false;
          if (mounted) context.go(completed ? '/home' : '/onboarding');
       } catch (e) {
         if (mounted) context.go('/onboarding');
       }
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Row
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "A"
                      SlideTransition(
                        position: _aSlide,
                        child:  Transform.scale(
                          scale: _aScale.value,
                          child: FadeTransition(
                            opacity: _aOpacity,
                            child: Text(
                              'A',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // "URA" (Clipped Reveal)
                      ClipRect(
                        child: SlideTransition(
                          position: _uraSlide,
                          child: FadeTransition(
                            opacity: _uraOpacity,
                            child: Text(
                              'URA',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // "STYLE" Subtitle
                FadeTransition(
                  opacity: _styleOpacity,
                  child: Text(
                    'STYLE',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD4AF37).withOpacity(0.8),
                      letterSpacing: _styleSpacing.value,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
