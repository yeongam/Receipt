import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/fixed_expense_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/fixed_expense_provider.dart';
import 'providers/notification_rule_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/intro/intro_screen.dart';
import 'screens/main_navigation_screen.dart';
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
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics();
      default:
        return const ClampingScrollPhysics();
    }
  }
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
  final _authRepository = AuthRepository();
  final _categoryRepository = CategoryRepository();
  final _fixedExpenseRepository = FixedExpenseRepository();
  final _transactionRepository = TransactionRepository();
  final _budgetRepository = BudgetRepository();
  final _notificationRepository = NotificationRepository();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(_authRepository)),
        ChangeNotifierProvider(
            create: (_) => CategoryProvider(_categoryRepository)),
        ChangeNotifierProvider(
            create: (_) => FixedExpenseProvider(_fixedExpenseRepository)),
        ChangeNotifierProvider(
            create: (_) => TransactionProvider(_transactionRepository)),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            authRepository: _authRepository,
            budgetRepository: _budgetRepository,
            notificationRepository: _notificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationRuleProvider(_notificationRepository),
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

enum _Stage { loading, intro, login, signup, main }

class _RootGateState extends State<_RootGate> {
  _Stage _stage = _Stage.loading;

  void _moveTo(_Stage stage) => setState(() => _stage = stage);

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().status;

    if (authStatus == AuthStatus.unknown) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authStatus == AuthStatus.authenticated && _stage != _Stage.main) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _stage != _Stage.main) setState(() => _stage = _Stage.main);
      });
    }

    if (authStatus == AuthStatus.unauthenticated &&
        (_stage == _Stage.main || _stage == _Stage.loading)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_stage == _Stage.main) {
          context.read<TransactionProvider>().clear();
          context.read<CategoryProvider>().clear();
          context.read<FixedExpenseProvider>().clear();
          context.read<NotificationRuleProvider>().clear();
          context.read<SettingsProvider>().resetForSignedOut();
        }
        setState(() => _stage = _Stage.intro);
      });
    }

    return switch (_stage) {
      _Stage.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
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
