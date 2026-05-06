import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/signed_in_user_id.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/fixed_expense_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/fixed_expense_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/intro/intro_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'screens/mypage/mypage_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  if (!SupabaseConfig.isConfigured) {
    runApp(const MissingSupabaseConfigApp());
    return;
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const MyApp());
}

class _AppScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}

class MissingSupabaseConfigApp extends StatelessWidget {
  const MissingSupabaseConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Supabase 설정이 필요합니다.\n'
              'SUPABASE_URL과 SUPABASE_ANON_KEY를 --dart-define으로 전달하세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final categoryRepository = CategoryRepository();
    final fixedExpenseRepository = FixedExpenseRepository();
    final transactionRepository = TransactionRepository();
    final budgetRepository = BudgetRepository();
    final notificationRepository = NotificationRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => FixedExpenseProvider(fixedExpenseRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(transactionRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            authRepository: authRepository,
            budgetRepository: budgetRepository,
            notificationRepository: notificationRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: '통합 지출관리',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scrollBehavior: _AppScrollBehavior(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

enum _Stage { intro, login, signup, main }

class _RootGateState extends State<_RootGate> {
  _Stage _stage = _Stage.intro;

  void _moveTo(_Stage stage) => setState(() => _stage = stage);

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().status;

    // Already authenticated: skip intro/login
    if (authStatus == AuthStatus.authenticated && _stage != _Stage.main) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _stage = _Stage.main);
      });
    }

    // Logged out: clear providers and go back to login
    if (authStatus == AuthStatus.unauthenticated && _stage == _Stage.main) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TransactionProvider>().clear();
        context.read<CategoryProvider>().clear();
        context.read<FixedExpenseProvider>().clear();
        context.read<SettingsProvider>().resetForSignedOut();
        setState(() => _stage = _Stage.login);
      });
    }

    return switch (_stage) {
      _Stage.intro => IntroScreen(onStart: () => _moveTo(_Stage.login)),
      _Stage.login => LoginScreen(
        onLogin: () => _moveTo(_Stage.main),
        onSignup: () => _moveTo(_Stage.signup),
      ),
      _Stage.signup => SignupScreen(
        onComplete: () => _moveTo(_Stage.main),
        onBackToLogin: () => _moveTo(_Stage.login),
      ),
      _Stage.main => const MainNavigationScreen(),
    };
  }
}

class _LaunchLoadingScreen extends StatefulWidget {
  const _LaunchLoadingScreen();

  @override
  State<_LaunchLoadingScreen> createState() => _LaunchLoadingScreenState();
}

class _LaunchLoadingScreenState extends State<_LaunchLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _progressWidthFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.76, curve: Curves.easeOut),
    );
    _progressWidthFactor = Tween<double>(
      begin: 0.28,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 1, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : Colors.white;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;
    final subtitleColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final ornamentPrimary = isDark
        ? AppColors.primary.withValues(alpha: 0.14)
        : AppColors.primaryLight.withValues(alpha: 0.65);
    final ornamentAccent = isDark
        ? AppColors.accent.withValues(alpha: 0.10)
        : AppColors.accentLight.withValues(alpha: 0.34);
    final progressTrackColor =
        isDark ? AppColors.darkSurfaceAlt : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ornamentPrimary,
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -40,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ornamentAccent,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: _iconOpacity.value,
                        child: const SizedBox(
                          width: 104,
                          height: 104,
                          child: Image(
                            image: AssetImage(
                              'assets/images/loading_logo.png',
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          '내돈내역',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: titleColor,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          '내 지출과 수입을 한눈에 관리하는 가계부',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: subtitleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Container(
                          width: 82,
                          height: 6,
                          decoration: BoxDecoration(
                            color: progressTrackColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progressWidthFactor.value,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = SettingsProvider.navigationIndexFor(
      context.read<SettingsProvider>().startScreen,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final userId = resolveSignedInUserId(context) ?? '';
    final now = DateTime.now();
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final fixedExpenseProvider = context.read<FixedExpenseProvider>();
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    await Future.wait([
      transactionProvider.loadMonth(userId, now),
      transactionProvider.loadMonthlyTrends(userId),
      categoryProvider.load(userId),
      fixedExpenseProvider.load(userId),
    ]);

    if (!mounted) return;

    final authUser = authProvider.user;
    if (authUser == null || !mounted) return;

    await settingsProvider.load(user: authUser);
    if (!mounted) return;
    setState(() {
      _currentIndex = SettingsProvider.navigationIndexFor(
        settingsProvider.startScreen,
      );
    });
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ReportScreen(),
    NotificationScreen(),
    MyPageScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: '홈',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: '내역',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: '리포트',
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: '알림',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: '마이',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentIndex = index),
                    splashColor: AppColors.primaryContainer,
                    highlightColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
