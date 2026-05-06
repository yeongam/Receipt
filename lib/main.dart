import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
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
import 'screens/shared/pin_pad.dart';
import 'screens/shared/transaction_entry_sheet.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
            create: (_) => CategoryProvider(categoryRepository)),
        ChangeNotifierProvider(
            create: (_) => FixedExpenseProvider(fixedExpenseRepository)),
        ChangeNotifierProvider(
            create: (_) => TransactionProvider(transactionRepository)),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            authRepository: authRepository,
            budgetRepository: budgetRepository,
            notificationRepository: notificationRepository,
          ),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '통합 지출관리',
            debugShowCheckedModeBanner: false,
            scrollBehavior: _AppScrollBehavior(),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeToken == 'dark'
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: Locale(settings.isEnglish ? 'en' : 'ko'),
            supportedLocales: const [Locale('ko'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.noScaling),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _RootGate(),
          );
        },
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

class _AppLockScreen extends StatefulWidget {
  final bool Function(String pin) validatePin;
  final Future<bool> Function(String code) validateRecoveryCode;
  final Future<void> Function() disableAppLock;
  final VoidCallback onUnlocked;
  final bool biometricEnabled;

  const _AppLockScreen({
    required this.validatePin,
    required this.validateRecoveryCode,
    required this.disableAppLock,
    required this.onUnlocked,
    this.biometricEnabled = false,
  });

  @override
  State<_AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<_AppLockScreen> {
  String _pin = '';
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;
  bool _showError = false;
  bool _biometricTriggered = false;

  @override
  void initState() {
    super.initState();
    if (widget.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _tryBiometric() async {
    if (_biometricTriggered) return;
    _biometricTriggered = true;
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck || !mounted) {
        _biometricTriggered = false; // allow manual retry
        return;
      }
      final authenticated = await auth.authenticate(
        localizedReason: '생체 인증으로 잠금을 해제하세요',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (authenticated && mounted) {
        widget.onUnlocked();
      } else {
        _biometricTriggered = false; // cancelled → allow retry via button
      }
    } catch (_) {
      _biometricTriggered = false; // error → allow retry via button
    }
  }

  void _onKey(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _showError = false;
    });
    if (_pin.length == 6) _submit();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    final ok = widget.validatePin(_pin);
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _failedAttempts++;
        _pin = '';
        _showError = true;
      });
      if (_failedAttempts >= _maxAttempts) {
        _showRecoveryDialog();
      }
    }
  }

  void _showRecoveryDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecoveryCodeUnlockDialog(
        validateCode: widget.validateRecoveryCode,
        disableLock: widget.disableAppLock,
        onUnlocked: widget.onUnlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.secondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'PIN 입력',
              style: AppTextStyles.displayLarge.copyWith(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_showError)
              Text(
                _failedAttempts >= _maxAttempts
                    ? '시도 횟수 초과'
                    : '잘못된 PIN입니다 ($_failedAttempts/$_maxAttempts)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.expense,
                ),
              )
            else
              const SizedBox(height: 18),
            const SizedBox(height: 24),
            PinDots(length: _pin.length),
            const SizedBox(height: 32),
            NumericPinPad(
              onDigitPressed: _onKey,
              onBackspacePressed: _onDelete,
            ),
            const SizedBox(height: 24),
            if (widget.biometricEnabled) ...[
              TextButton.icon(
                onPressed: _tryBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('생체 인증으로 해제'),
              ),
              const SizedBox(height: 4),
            ],
            TextButton(
              onPressed: _showRecoveryDialog,
              child: Text(
                'PIN을 잊으셨나요?',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _RecoveryCodeUnlockDialog extends StatefulWidget {
  final Future<bool> Function(String code) validateCode;
  final Future<void> Function() disableLock;
  final VoidCallback onUnlocked;

  const _RecoveryCodeUnlockDialog({
    required this.validateCode,
    required this.disableLock,
    required this.onUnlocked,
  });

  @override
  State<_RecoveryCodeUnlockDialog> createState() =>
      _RecoveryCodeUnlockDialogState();
}

class _RecoveryCodeUnlockDialogState
    extends State<_RecoveryCodeUnlockDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await widget.validateCode(_controller.text.trim());
    if (ok) {
      await widget.disableLock();
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onUnlocked();
    } else {
      setState(() => _showError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('복구 코드로 잠금 해제'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('앱잠금 설정 시 발급된 복구 코드를 입력하세요.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: '복구 코드',
              errorText: _showError ? '올바르지 않은 복구 코드입니다.' : null,
            ),
            onChanged: (_) => setState(() => _showError = false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('확인'),
        ),
      ],
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
  bool _isLocked = false;
  bool _isDataReady = false;
  Offset? _fabOffset;
  bool _isDraggingFab = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = SettingsProvider.navigationIndexFor(
      context.read<SettingsProvider>().startScreen,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _loadInitialData();
      } catch (e) {
        debugPrint('[MainNav] _loadInitialData failed: $e');
      }
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      final isLocked = settings.hasAppLock && settings.lockOnLaunch;
      setState(() {
        _isDataReady = true;
        _isLocked = isLocked;
      });
      // Notification permission popup must not appear before the lock gate.
      if (!isLocked) _initNotificationService();
    });
  }

  Future<void> _loadInitialData() async {
    final userId = resolveSignedInUserId(context) ?? '';
    final now = DateTime.now();
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    // Load settings FIRST — must complete before the lock check in initState.
    // Financial-data failures must not skip this step.
    final authUser = authProvider.user;
    if (authUser != null) {
      await settingsProvider.load(user: authUser);
    }
    if (!mounted) return;

    // Financial data: absorb individual failures so a single network error
    // cannot leave settings unloaded and the lock gate open.
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final fixedExpenseProvider = context.read<FixedExpenseProvider>();

    await Future.wait<void>([
      transactionProvider.loadMonth(userId, now).catchError((Object _) {}),
      transactionProvider.loadMonthlyTrends(userId).catchError((Object _) {}),
      categoryProvider.load(userId).catchError((Object _) {}),
      fixedExpenseProvider.load(userId).catchError((Object _) {}),
    ]);

    if (!mounted) return;

    // Initialize the notification plugin (no OS popup — permission is
    // requested later, after the lock gate is resolved).
    await NotificationService.instance.initialize();

    if (!mounted) return;
    setState(() {
      _currentIndex = SettingsProvider.navigationIndexFor(
        settingsProvider.startScreen,
      );
    });
  }

  /// Requests notification permission and syncs schedules.
  /// Called only after the app lock gate is resolved to avoid showing
  /// an OS permission popup before the lock screen.
  Future<void> _initNotificationService() async {
    if (!mounted) return;
    final settingsProvider = context.read<SettingsProvider>();
    final notificationService = NotificationService.instance;
    final granted = await notificationService.requestPermissions();
    if (granted && mounted) {
      final notificationSetting = settingsProvider.notificationSetting;
      final fixedExpenses = context.read<FixedExpenseProvider>().items;
      if (notificationSetting != null) {
        await notificationService.syncSchedules(
          setting: notificationSetting,
          activeFixedExpenses: fixedExpenses,
          isEnglish: settingsProvider.isEnglish,
        );
      }
    }
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
    if (_isLocked) {
      final settings = context.read<SettingsProvider>();
      return _AppLockScreen(
        validatePin: settings.validateAppLockPasscode,
        validateRecoveryCode: settings.validateRecoveryCodeForUnlock,
        disableAppLock: settings.disableAppLock,
        onUnlocked: () {
          setState(() => _isLocked = false);
          _initNotificationService();
        },
        biometricEnabled: settings.biometric,
      );
    }
    // While loading, show blank screen to prevent data exposure before lock check
    if (!_isDataReady) {
      final theme = Theme.of(context);
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor);
    }
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          const fabSize = 56.0;
          const horizontalMargin = 16.0;
          const bottomMargin = 16.0;
          const topMargin = 96.0;
          const railInset = 16.0;

          _fabOffset ??= Offset(
            constraints.maxWidth - fabSize - horizontalMargin,
            constraints.maxHeight - fabSize - bottomMargin,
          );

          const leftRail = railInset;
          final rightRail =
              (constraints.maxWidth - fabSize - railInset).clamp(0.0, double.infinity);
          final maxX =
              (constraints.maxWidth - fabSize).clamp(0.0, double.infinity);
          const minY = topMargin;
          final maxY = (constraints.maxHeight - fabSize - bottomMargin)
              .clamp(minY, double.infinity);
          final clampedOffset = Offset(
            _fabOffset!.dx.clamp(0.0, maxX),
            _fabOffset!.dy.clamp(minY, maxY),
          );
          if (clampedOffset != _fabOffset) _fabOffset = clampedOffset;

          void snapFabToRail() {
            final current = _fabOffset!;
            final snapX =
                (current.dx - leftRail).abs() < (current.dx - rightRail).abs()
                    ? leftRail
                    : rightRail;
            setState(() {
              _isDraggingFab = false;
              _fabOffset = Offset(snapX, current.dy.clamp(minY, maxY));
            });
          }

          return Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
              AnimatedPositioned(
                duration: _isDraggingFab
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: _fabOffset!.dx,
                top: _fabOffset!.dy,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _isDraggingFab = true),
                  onPanUpdate: (details) {
                    setState(() {
                      _fabOffset = Offset(
                        (_fabOffset!.dx + details.delta.dx).clamp(0.0, maxX),
                        (_fabOffset!.dy + details.delta.dy).clamp(minY, maxY),
                      );
                    });
                  },
                  onPanEnd: (_) => snapFabToRail(),
                  onPanCancel: snapFabToRail,
                  child: FloatingActionButton(
                    onPressed: () => openQuickAddHub(context),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add_rounded, size: 28),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
            height: 76,
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
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
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
