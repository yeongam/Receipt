import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/signed_in_user_id.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/fixed_expense_provider.dart';
import '../providers/notification_rule_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/notification_service.dart';
import 'auth/app_lock_screen.dart';
import 'home/home_screen.dart';
import 'history/history_screen.dart';
import 'report/report_screen.dart';
import 'notification/notification_screen.dart';
import 'mypage/mypage_screen.dart';
import 'shared/transaction_entry_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const Duration _initialLoadTimeout = Duration(seconds: 12);
  static const Duration _initialSectionTimeout = Duration(seconds: 5);

  int _currentIndex = 0;
  bool _isLocked = false;
  bool _isDataReady = false;
  Offset? _fabOffset;
  bool _isDraggingFab = false;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const HistoryScreen(),
      const ReportScreen(),
      const NotificationScreen(),
      MyPageScreen(onLogout: () => setState(() => _currentIndex = 0)),
    ];
    _currentIndex = SettingsProvider.navigationIndexFor(
      context.read<SettingsProvider>().startScreen,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _loadInitialData().timeout(
          _initialLoadTimeout,
          onTimeout: () => debugPrint('[MainNav] _loadInitialData timed out'),
        );
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
      if (!isLocked) _initNotificationService();
    });
  }

  Future<void> _loadInitialData() async {
    final userId = resolveSignedInUserId(context) ?? '';
    final now = DateTime.now();
    final authProvider = context.read<AuthProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    final authUser = authProvider.user;
    if (authUser != null) {
      await settingsProvider.load(user: authUser);
    }
    if (!mounted) return;

    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final fixedExpenseProvider = context.read<FixedExpenseProvider>();

    await Future.wait<void>([
      _loadSection(
        'loadMonth',
        () => transactionProvider.loadMonth(userId, now),
      ),
      _loadSection(
        'loadMonthlyTrends',
        () => transactionProvider.loadMonthlyTrends(userId),
      ),
      _loadSection('loadCategories', () => categoryProvider.load(userId)),
      _loadSection(
        'loadFixedExpenses',
        () => fixedExpenseProvider.load(userId),
      ),
      _loadSection(
        'loadNotificationRules',
        () => context.read<NotificationRuleProvider>().load(userId),
      ),
    ]);

    if (!mounted) return;
    setState(() {
      _currentIndex = SettingsProvider.navigationIndexFor(
        settingsProvider.startScreen,
      );
    });
  }

  Future<void> _loadSection(
    String label,
    Future<void> Function() action,
  ) async {
    try {
      await action().timeout(_initialSectionTimeout);
    } catch (e) {
      debugPrint('[MainNav] $label failed: $e');
    }
  }

  Future<void> _initNotificationService() async {
    if (!mounted) return;
    try {
      final settingsProvider = context.read<SettingsProvider>();
      final notificationService = NotificationService.instance;
      final granted = await notificationService.requestPermissions();
      if (granted && mounted) {
        final notificationSetting = settingsProvider.notificationSetting;
        final fixedExpenses = context.read<FixedExpenseProvider>().items;
        final rules = context.read<NotificationRuleProvider>().rules;
        if (notificationSetting != null) {
          await notificationService.syncSchedules(
            setting: notificationSetting,
            activeFixedExpenses: fixedExpenses,
            isEnglish: settingsProvider.isEnglish,
            rules: rules,
          );
        }
      }
    } catch (e) {
      debugPrint('[MainNav] notification initialization failed: $e');
    }
  }

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
      return Consumer<SettingsProvider>(
        builder: (context, settings, _) => AppLockScreen(
          validatePin: settings.validateAppLockPasscode,
          validateRecoveryCode: settings.validateRecoveryCodeForUnlock,
          disableAppLock: settings.disableAppLock,
          onUnlocked: () {
            setState(() => _isLocked = false);
            _initNotificationService();
          },
          biometricEnabled: settings.biometric,
        ),
      );
    }
    if (!_isDataReady) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
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
          final rightRail = (constraints.maxWidth - fabSize - railInset).clamp(
            0.0,
            double.infinity,
          );
          final maxX = (constraints.maxWidth - fabSize).clamp(
            0.0,
            double.infinity,
          );
          const minY = topMargin;
          final maxY = (constraints.maxHeight - fabSize - bottomMargin).clamp(
            minY,
            double.infinity,
          );
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
          color: Theme.of(context).colorScheme.surface,
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
