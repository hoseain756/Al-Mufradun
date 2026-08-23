import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_icons.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late final AnimationController _animCtrl;


  static const _pages = [
    _OnboardingPage(
      icon: OctIcons.home,
      title: 'مرحباً بك في المفردون',
      description: '«سَبَقَ الْمُفَرِّدُونَ» — واحتك الإيمانية المتكاملة لتعطير لسانك بذكر الله في كل وقت وحين',
    ),
    _OnboardingPage(
      icon: OctIcons.book,
      title: 'القرآن الكريم',
      description:
          'القرآن الكريم كاملاً بين يديك بصياغة بصرية مريحة للعين، ممتداً بمميزات تفاعلية تتيح لك مشاركة الآيات الكريمة مع من تحب',
    ),
    _OnboardingPage(
      icon: OctIcons.clock,
      title: 'مواقيت الصلاة والقبلة',
      description:
          'صلاتك عماد دينك؛ تابع مواقيت الصلاة بدقة واعرف اتجاه قبلتك أينما كنت في أرجاء الأرض لتكون دائماً على صلة بخالقك',
    ),
    _OnboardingPage(
      icon: OctIcons.heart,
      title: 'الأذكار والأدعية اليومية',
      description:
          'حصن مسيرك؛ عطر أنفاسك بأذكار الصباح والمساء ونخبة من الأدعية المأثورة لتجعل قلبك مطمئناً بذكر الله طوال يومك',
    ),
    _OnboardingPage(
      icon: null,
      title: 'ابدأ رحلتك',
      description: 'وعلى الله الاتكال — لننطلق في رحاب الطاعة والذكر',
      isGetStarted: true,
    ),
  ];

  
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    context.read<AppProvider>().completeOnboarding();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'تخطي',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (page.icon != null)
                            Icon(
                              page.icon,
                              size: 80,
                              color: colorScheme.primary,
                            ),
                          const SizedBox(height: 24),
                          Text(
                            page.title,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Text(
                              page.description,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom: dots + navigation button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(left: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Navigation button
                  if (isLastPage)
                    FilledButton(
                      onPressed: _completeOnboarding,
                      child: const Text('ابدأ'),
                    )
                  else
                    FilledButton.tonal(
                      onPressed: _nextPage,
                      child: const Text('التالي'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData? icon;
  final String title;
  final String description;
  final bool isGetStarted;

  const _OnboardingPage({
    this.icon,
    required this.title,
    required this.description,
    this.isGetStarted = false,
  });
}
