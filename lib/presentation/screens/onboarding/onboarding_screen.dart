import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.auto_graph_rounded,
      color: AppTheme.primary,
      title: 'AI-Powered Trading',
      subtitle:
          'Advanced machine learning algorithms analyze digit patterns '
          'in real-time to predict market movements with high confidence.',
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      color: AppTheme.secondary,
      title: 'Smart Risk Management',
      subtitle:
          'Automated stop-loss and daily profit targets protect your '
          'capital. Set your own risk parameters and trade with confidence.',
    ),
    _OnboardingPage(
      icon: Icons.speed_rounded,
      color: AppTheme.accent,
      title: 'Real-Time Deriv Market',
      subtitle:
          'Direct WebSocket connection to Deriv markets for instant '
          'tick data, live execution and balance updates.',
    ),
    _OnboardingPage(
      icon: Icons.insights_rounded,
      color: AppTheme.warning,
      title: 'Optimize & Adapt',
      subtitle:
          'Auto-scan markets to find the most stable conditions. '
          'The AI learns from every trade to improve predictions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () =>
                    Get.find<AuthController>().completeOnboarding(),
                child: const Text(
                  'Skip',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: page.color.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: page.color.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                page.icon,
                                color: page.color,
                                size: 56,
                              ),
                            )
                            .animate(key: ValueKey(index))
                            .fadeIn(duration: 500.ms)
                            .scale(begin: const Offset(0.7, 0.7)),
                        const SizedBox(height: 40),
                        Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: page.color,
                                letterSpacing: 1,
                              ),
                            )
                            .animate(key: ValueKey('t$index'))
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.2),
                        const SizedBox(height: 16),
                        Text(
                              page.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                                height: 1.6,
                              ),
                            )
                            .animate(key: ValueKey('s$index'))
                            .fadeIn(delay: 350.ms),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i
                        ? AppTheme.primary
                        : AppTheme.border,
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Get.find<AuthController>().completeOnboarding();
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
