import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

/// Onboarding screen shown to first-time users
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});

  /// Check if onboarding has been completed
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.hub,
      title: 'Welcome to NexUs',
      subtitle: 'Your campus connection hub.\nEverything you need in one place.',
      color: AppColors.primary,
      imagePath: 'lib/assets/images/onboarding.png',
    ),
    _SlideData(
      icon: Icons.groups,
      title: 'Join Communities',
      subtitle: 'Discover clubs, find study buddies,\nand connect with peers.',
      color: AppColors.clubsColor,
      imagePath: 'lib/assets/images/empty_clubs.png',
    ),
    _SlideData(
      icon: Icons.event,
      title: 'Never Miss Events',
      subtitle: 'Stay updated with campus events,\nhackathons, and workshops.',
      color: AppColors.eventsColor,
      imagePath: 'lib/assets/images/empty_events.png',
    ),
    _SlideData(
      icon: Icons.school,
      title: 'Learn & Grow',
      subtitle: 'Access resources, get mentorship,\nand ace your academics.',
      color: AppColors.mentorshipColor,
      imagePath: 'lib/assets/images/feature_mentorship.png',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticUtils.lightTap();
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _complete() {
    HapticUtils.success();
    OnboardingScreen.markCompleted();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: Text(
                  'Skip',
                  style: TextStyle(color: context.appColors.textTertiary),
                ),
              ),
            ),
            
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _OnboardingSlide(data: _slides[i], isFirst: i == 0),
              ),
            ),
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i 
                        ? _slides[_currentPage].color 
                        : context.appColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slides[_currentPage].color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage < _slides.length - 1 ? 'Next' : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? imagePath; // Optional custom image
  
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.imagePath,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _SlideData data;
  final bool isFirst;
  
  const _OnboardingSlide({required this.data, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show logo image for first slide, icon for others
          if (isFirst) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'lib/assets/images/logo.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildIcon(context),
              ),
            ),
          ] else if (data.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                data.imagePath!,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildIcon(context),
              ),
            ),
          ] else ...[
            _buildIcon(context),
          ],
          const SizedBox(height: 48),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: context.appColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        data.icon,
        size: 80,
        color: data.color,
      ),
    );
  }
}
