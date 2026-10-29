import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/onboarding/onboarding_assets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Small Steps\nBig Changes',
      'subtitle': 'Track your habits, build consistency\nand become a better you.',
      'imagePath': 'assets/images/onboarding_1.png',
      'imageBytes': kOnboarding1Bytes,
    },
    {
      'title': 'Create Habits\nThat Fit Your Life',
      'subtitle': 'Choose from a variety of habits or\ncreate your own.',
      'imagePath': 'assets/images/onboarding_2.png',
      'imageBytes': kOnboarding2Bytes,
    },
    {
      'title': 'Track Progress\nStay Motivated',
      'subtitle': 'See your streaks, statistics and\nachievements.',
      'imagePath': 'assets/images/onboarding_3.png',
      'imageBytes': kOnboarding3Bytes,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/main/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle ambient floating leaves in background
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.04 : 0.06,
                child: Image.memory(
                  kFloatingLeavesAccentBytes,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),

            Column(
              children: [
                // Top Row: Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/main/home'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page View with the 3 onboarding screens
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration Container with Soft Circular Mint Aura
                            SizedBox(
                              width: size.width * 0.72,
                              height: size.height * 0.36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Soft radial watercolor aura
                                  Container(
                                    width: size.width * 0.65,
                                    height: size.width * 0.65,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          (isDark ? const Color(0xFF166534) : const Color(0xFFDCFCE7))
                                              .withOpacity(isDark ? 0.3 : 0.6),
                                          (isDark ? const Color(0xFF0F172A) : Colors.white)
                                              .withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // High Fidelity 3D Illustration with 100% Transparent Background
                                  Image.memory(
                                    page['imageBytes'],
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Bold Headline
                            Text(
                              page['title'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: -0.6,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Supporting Description
                            Text(
                              page['subtitle'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Page Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 10 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF15803D)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Bottom CTA Button: "Next" or "Get Started"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _onNextPressed,
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
