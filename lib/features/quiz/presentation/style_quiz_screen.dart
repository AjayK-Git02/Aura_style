import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aura_style/core/theme/app_theme.dart';
import 'package:aura_style/core/widgets/primary_button.dart';
import 'package:aura_style/features/auth/application/auth_controller.dart';

class StyleQuizScreen extends ConsumerStatefulWidget {
  const StyleQuizScreen({super.key});

  @override
  ConsumerState<StyleQuizScreen> createState() => _StyleQuizScreenState();
}

class _StyleQuizScreenState extends ConsumerState<StyleQuizScreen> {
  final PageController _pageController = PageController();
  int _currentQuestionIndex = 0;
  bool _isAnalyzing = false;
  bool _showResults = false;
  
  // Store user answers: Map<QuestionIndex, SelectedOption>
  final Map<int, QuizOption> _answers = {};
  List<String> _calculatedStyles = [];

  final List<QuizQuestion> _questions = [
    QuizQuestion(
      title: 'The Perfect Evening',
      subtitle: "It's Saturday night. The vibe is...",
      options: [
        QuizOption('Hidden Speakeasy', ['Vintage', 'Elegant', 'Classic']),
        QuizOption('Rooftop Lounge', ['Chic', 'Streetwear', 'Glam']),
        QuizOption('Beach Bonfire', ['Bohemian', 'Casual']),
        QuizOption('Art Gallery Warehouse', ['Avant-Garde', 'Minimalist']),
      ],
    ),
    QuizQuestion(
      title: 'The Daily Driver',
      subtitle: "You have 5 mins to get ready. You grab...",
      options: [
        QuizOption('Crisp White Shirt', ['Formal', 'Minimalist', 'Classic']),
        QuizOption('Oversized Hoodie', ['Streetwear', 'Grunge']),
        QuizOption('Flowy Maxi Dress', ['Bohemian', 'Vintage']),
        QuizOption('Tracksuit & Sneakers', ['Sporty', 'Casual']),
      ],
    ),
    QuizQuestion(
      title: 'Statement Piece',
      subtitle: "You feel naked without...",
      options: [
        QuizOption('Structured Blazer', ['Formal', 'Chic', 'Elegant']),
        QuizOption('Leather Jacket', ['Grunge', 'Vintage', 'Edgy']),
        QuizOption('Bold Sunglasses', ['Avant-Garde', 'Streetwear']),
        QuizOption('Classic Watch', ['Elegant', 'Classic', 'Minimalist']),
      ],
    ),
    QuizQuestion(
      title: 'Dream Destination',
      subtitle: "Your soul belongs in...",
      options: [
        QuizOption('Paris', ['Chic', 'Elegant', 'Classic']),
        QuizOption('Tokyo', ['Avant-Garde', 'Streetwear']),
        QuizOption('Tulum', ['Bohemian', 'Casual']),
        QuizOption('New York', ['Formal', 'Minimalist', 'Streetwear']),
      ],
    ),
    QuizQuestion(
      title: 'Texture & Touch',
      subtitle: "What fabric feels like home?",
      options: [
        QuizOption('Silk & Satin', ['Elegant', 'Chic', 'Glam']),
        QuizOption('Worn-in Denim', ['Casual', 'Streetwear', 'Vintage']),
        QuizOption('Raw Linen', ['Bohemian', 'Minimalist']),
        QuizOption('Leather & Studs', ['Grunge', 'Edgy']),
      ],
    ),
    QuizQuestion(
      title: 'The Soundtrack',
      subtitle: "Your headphones are playing...",
      options: [
        QuizOption('Jazz / Classical', ['Classic', 'Formal', 'Elegant']),
        QuizOption('Lo-Fi / Indie', ['Minimalist', 'Casual', 'Bohemian']),
        QuizOption('Techno / House', ['Avant-Garde', 'Streetwear']),
        QuizOption('Rock / Punk', ['Grunge', 'Vintage']),
      ],
    ),
    QuizQuestion(
      title: 'Interior Design',
      subtitle: "Your dream living room looks like...",
      options: [
        QuizOption('Mid-Century Modern', ['Vintage', 'Classic']),
        QuizOption('Industrial Loft', ['Streetwear', 'Edgy']),
        QuizOption('Velvet & Gold', ['Elegant', 'Chic', 'Glam']),
        QuizOption('Plant-Filled Sanctuary', ['Bohemian', 'Casual']),
      ],
    ),
    QuizQuestion(
      title: 'Forever Footwear',
      subtitle: "You can only wear one pair forever...",
      options: [
        QuizOption('Crisp Sneakers', ['Streetwear', 'Sporty']),
        QuizOption('Combat Boots', ['Grunge', 'Avant-Garde']),
        QuizOption('Loafers / Oxfords', ['Preppy', 'Formal', 'Classic']),
        QuizOption('Sleek Heels / Boots', ['Chic', 'Elegant']),
      ],
    ),
  ];

  void _nextPage() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _calculateAndSaveAura();
    }
  }

  void _selectOption(QuizOption option) {
    setState(() {
      _answers[_currentQuestionIndex] = option;
    });
    
    // Auto advance after a brief delay for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _nextPage();
    });
  }

  Future<void> _calculateAndSaveAura() async {
    setState(() => _isAnalyzing = true);

    // Tally up the styles
    final styleCounts = <String, int>{};
    for (final option in _answers.values) {
      for (final style in option.styles) {
        styleCounts[style] = (styleCounts[style] ?? 0) + 1;
      }
    }

    final sortedStyles = styleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topStyles = sortedStyles.take(5).map((e) => e.key).toList();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Analysis effect

      if (mounted) {
        await ref.read(authControllerProvider.notifier).updateProfile(
              stylePreferences: topStyles,
            );
        
        if (mounted) {
           setState(() {
            _isAnalyzing = false;
            _showResults = true;
            _calculatedStyles = topStyles;
          });
        }
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isAnalyzing = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _showResults = false;
      _answers.clear();
      _calculatedStyles = [];
    });
    // Jump back to start
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Analyzing State
    if (_isAnalyzing) {
       return const Scaffold(
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text('Analyzing your Aura...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    // 2. Results View (New Panel)
    if (_showResults) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Aura Defined',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your unique style profile is ready.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _calculatedStyles.map((style) => Chip(
                    label: Text(style.toUpperCase()),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                    labelStyle: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  )).toList(),
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: 'ENTER WARDROBE',
                  onPressed: () => context.go('/home'),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _retakeQuiz,
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  label: const Text(
                    'Retake Quiz', 
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Quiz Flow (Questions)
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Refine Your Aura',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.white10,
            color: AppTheme.primaryColor,
            minHeight: 4,
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Question ${index + 1}/${_questions.length}',
                        style: TextStyle(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            letterSpacing: 2,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        question.title,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        question.subtitle,
                        style: GoogleFonts.lato(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 48),
                       // Options
                      ...question.options.map((option) {
                        final isSelected = _answers[index] == option;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: () => _selectOption(option),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.white10,
                                ),
                              ),
                              child: Text(
                                option.text,
                                style: GoogleFonts.lato(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class QuizQuestion {
  final String title;
  final String subtitle;
  final List<QuizOption> options;

  QuizQuestion({
    required this.title,
    required this.subtitle,
    required this.options,
  });
}

class QuizOption {
  final String text;
  final List<String> styles;

  QuizOption(this.text, this.styles);
}
