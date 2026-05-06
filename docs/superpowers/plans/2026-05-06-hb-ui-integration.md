# HB UI Integration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Money_Management(Supabase 백엔드)에 HB의 UI 기능(다크테마·i18n·드래그 FAB·앱잠금·런치 로딩·알림서비스)을 레이어별 순서로 통합한다.

**Architecture:** 기존 Supabase 백엔드를 유지하면서 HB의 UI 구조를 이식. 충돌 시 항상 Supabase 패턴으로 변환. AppUser 테이블에 앱잠금 컬럼 추가, SettingsProvider에 app lock 메서드 + locale getter 추가, 새 NotificationService로 Supabase 규칙 → 로컬 알림 브리지 구성.

**Tech Stack:** Flutter, Supabase, provider, flutter_local_notifications, local_auth, crypto, flutter_localizations, flutter_timezone, timezone

**Base project:** `/Volumes/ORICO/Money_Management`
**UI source:** `/Volumes/ORICO/HB`

---

## Chunk 1: Foundation — pubspec, theme, shared widgets

### Task 1: pubspec.yaml — 의존성 추가

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: pubspec.yaml 수정**

`dependencies:` 블록에 아래 항목 추가, `intl` 버전 업데이트:

```yaml
  flutter_localizations:
    sdk: flutter
  local_auth: ^2.3.0
  crypto: ^3.0.6
  flutter_local_notifications: ^19.4.2
  flutter_timezone: ^4.1.1
  timezone: ^0.10.1
```

`intl: ^0.19.0` → `intl: ^0.20.2` 로 변경.

- [ ] **Step 2: 패키지 가져오기**

```bash
cd /Volumes/ORICO/Money_Management && flutter pub get
```

예상 출력: `Got dependencies!` — 오류 없음.

- [ ] **Step 3: 빌드 확인**

```bash
flutter analyze --no-fatal-infos 2>&1 | tail -5
```

예상 출력: `No issues found!` 또는 기존 경고만.

- [ ] **Step 4: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add pubspec.yaml pubspec.lock
git -C /Volumes/ORICO/Money_Management commit -m "chore: add flutter_localizations, local_auth, crypto, notification packages"
```

---

### Task 2: app_text_styles.dart — HB 스타일 추가

**Files:**
- Modify: `lib/core/theme/app_text_styles.dart`

현재 Money_Management `app_text_styles.dart`에 없고 HB에 있는 항목:
- `amount`, `amountSmall`, `metric`에 `fontFeatures: [FontFeature.tabularFigures()]` 추가
- `sectionEyebrow` 스타일 추가

- [ ] **Step 1: amount에 tabularFigures 추가**

`lib/core/theme/app_text_styles.dart` 에서:

```dart
// 기존
  static const TextStyle amount = TextStyle(
    fontSize: 31,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.2,
  );

  static const TextStyle amountSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
  );
```

→ 아래로 교체:

```dart
  static const TextStyle amount = TextStyle(
    fontSize: 31,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle amountSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );
```

- [ ] **Step 2: metric에 tabularFigures 추가**

```dart
// 기존
  static const TextStyle metric = TextStyle(
    fontSize: 31,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
  );
```

→:

```dart
  static const TextStyle metric = TextStyle(
    fontSize: 31,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
```

- [ ] **Step 3: sectionEyebrow 추가**

`sectionTitle` 정의 바로 위에 삽입:

```dart
  static const TextStyle sectionEyebrow = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 0.2,
    height: 1.4,
  );
```

- [ ] **Step 4: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 5: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/core/theme/app_text_styles.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add tabularFigures to amount styles, add sectionEyebrow"
```

---

### Task 3: app_theme.dart — chipTheme + bottomNavigationBarTheme 추가

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

현재 Money_Management `app_theme.dart`에 없고 HB에 있는 항목:
- `lightTheme`과 `darkTheme` 모두에 `chipTheme`, `bottomNavigationBarTheme` 추가

- [ ] **Step 1: lightTheme에 추가**

`lightTheme` 의 `cardTheme: CardThemeData(...)` 블록 바로 **앞**에 삽입:

```dart
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceAlt,
        secondarySelectedColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle:
            AppTextStyles.labelMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.navLabelSelected,
        unselectedLabelStyle: AppTextStyles.navLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
```

- [ ] **Step 2: darkTheme에 추가**

`darkTheme` 의 `cardTheme: CardThemeData(...)` 블록 바로 **앞**에 삽입:

```dart
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.darkSurfaceAlt,
        secondarySelectedColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelStyle: AppTextStyles.labelMedium
            .copyWith(color: AppColors.darkTextSecondary),
        secondaryLabelStyle:
            AppTextStyles.labelMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        selectedLabelStyle: AppTextStyles.navLabelSelected,
        unselectedLabelStyle: AppTextStyles.navLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
```

- [ ] **Step 3: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 4: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/core/theme/app_theme.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add chipTheme and bottomNavigationBarTheme to light/dark themes"
```

---

### Task 4: app_preferences_format.dart — locale getter 추가

**Files:**
- Modify: `lib/core/utils/app_preferences_format.dart`

현재 Money_Management에 `tr()`, `isEnglish` 있음. `locale` getter 및 날짜/기간 포맷 메서드 추가.

- [ ] **Step 1: locale getter 추가**

`isEnglish` getter 바로 아래에 삽입:

```dart
  Locale get appLocale => Locale(isEnglish ? 'en' : 'ko');
```

- [ ] **Step 2: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 3: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/core/utils/app_preferences_format.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add appLocale getter to AppPreferencesFormatX"
```

---

### Task 5: pin_pad.dart 추가

**Files:**
- Create: `lib/screens/shared/pin_pad.dart`

HB의 파일을 Money_Management에 그대로 복사. import 경로는 동일(`../../core/theme/`).

- [ ] **Step 1: 파일 복사**

```bash
cp /Volumes/ORICO/HB/lib/screens/shared/pin_pad.dart \
   /Volumes/ORICO/Money_Management/lib/screens/shared/pin_pad.dart
```

- [ ] **Step 2: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 3: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/screens/shared/pin_pad.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add PinDots and NumericPinPad widgets from HB"
```

---

### Task 6: edge_overscroll_background.dart 추가

**Files:**
- Create: `lib/screens/shared/edge_overscroll_background.dart`

- [ ] **Step 1: 파일 복사**

```bash
cp /Volumes/ORICO/HB/lib/screens/shared/edge_overscroll_background.dart \
   /Volumes/ORICO/Money_Management/lib/screens/shared/edge_overscroll_background.dart
```

- [ ] **Step 2: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 3: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/screens/shared/edge_overscroll_background.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add EdgeOverscrollBackground widget from HB"
```

---

## Chunk 2: main.dart 재구성

### Task 7: _LaunchLoadingScreen 추가

**Files:**
- Modify: `lib/main.dart`
- Copy asset: `assets/images/loading_logo.png`

`main.dart` 파일 맨 아래(마지막 `}` 앞)에 `_LaunchLoadingScreen` 클래스 추가. HB의 구현체를 그대로 이식.

- [ ] **Step 0: loading_logo.png 에셋 복사**

HB에서 Money_Management로 로고 이미지 복사:

```bash
cp /Volumes/ORICO/HB/assets/images/loading_logo.png \
   /Volumes/ORICO/Money_Management/assets/images/loading_logo.png
```

파일 존재 확인:

```bash
ls /Volumes/ORICO/Money_Management/assets/images/
```

- [ ] **Step 1: import 추가**

`main.dart` 상단 import 블록에 추가:

```dart
import 'package:intl/date_symbol_data_local.dart';
```

(이미 있으면 스킵)

- [ ] **Step 2: _LaunchLoadingScreen 클래스 추가**

`main.dart` 맨 아래에 추가:

```dart
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
    _progressWidthFactor = Tween<double>(begin: 0.28, end: 1).animate(
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
                            image: AssetImage('assets/images/loading_logo.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          '통합 지출관리',
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
```

- [ ] **Step 3: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 4: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/main.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add _LaunchLoadingScreen with animation"
```

---

### Task 8: _AppScrollBehavior + textScaler 추가

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: _AppScrollBehavior 클래스 추가**

`main.dart` 맨 아래(또는 `_LaunchLoadingScreen` 바로 앞)에 추가:

```dart
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
```

- [ ] **Step 2: MyApp.build()에서 적용**

기존 `MaterialApp(...)` 에서 `scrollBehavior` 와 `builder` (textScaler) 추가:

```dart
// 기존 MaterialApp 내부에 추가
scrollBehavior: const _AppScrollBehavior(),
builder: (context, child) {
  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
    child: child ?? const SizedBox.shrink(),
  );
},
```

- [ ] **Step 3: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 4: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/main.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add BouncingScrollPhysics and textScaler.noScaling globally"
```

---

### Task 9: _AppLockScreen + PIN retry 추가

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/screens/shared/transaction_entry_sheet.dart` (openQuickAddHub import — 드래그 FAB Task에서)

HB의 `_AppLockScreen` 을 이식하되, `settings.isEnglish` 참조는 `SettingsProvider.isEnglish` 사용, `context.tr()` 사용. PIN 재시도 5회 초과 시 복구 코드 화면 전환.

- [ ] **Step 1: import 추가**

`main.dart` 상단에 추가:

```dart
import 'package:local_auth/local_auth.dart';
import 'screens/shared/pin_pad.dart';
```

- [ ] **Step 2: _AppLockScreen 클래스 추가**

`main.dart` 에 추가 (전체 클래스):

```dart
class _AppLockScreen extends StatefulWidget {
  const _AppLockScreen({
    required this.onUnlocked,
  });
  final VoidCallback onUnlocked;

  @override
  State<_AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<_AppLockScreen> {
  final _passcodeController = TextEditingController();
  final _localAuthentication = LocalAuthentication();
  String? _errorText;
  bool _isAuthenticating = false;
  bool _hasAutoTriedBiometric = false;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      if (settings.biometric) _tryBiometricUnlock(auto: true);
    });
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('앱 잠금 해제', 'Unlock app'),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        '설정한 4자리 숫자 비밀번호를 입력하세요.',
                        'Enter your 4-digit PIN.',
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 22),
                    PinDots(length: _passcodeController.text.length),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    NumericPinPad(
                      onDigitPressed: _appendDigit,
                      onBackspacePressed: _removeDigit,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _passcodeController.text.length == 4
                          ? _submitPasscode
                          : null,
                      child: Text(context.tr('잠금 해제', 'Unlock')),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _showRecoveryCodeDialog,
                      child: Text(
                        context.tr(
                          '비밀번호를 잊으셨나요? 복구 코드로 들어가기',
                          'Forgot PIN? Use recovery code',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (settings.biometric) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _isAuthenticating ? null : _tryBiometricUnlock,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(
                            context.tr('생체 인증으로 열기', 'Use biometrics')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitPasscode() {
    final passcode = _passcodeController.text.trim();
    final settings = context.read<SettingsProvider>();
    if (!settings.validateAppLockPasscode(passcode)) {
      _retryCount++;
      if (_retryCount >= _maxRetries) {
        _showRecoveryCodeDialog();
        return;
      }
      setState(() {
        _errorText = settings.isEnglish
            ? 'Wrong PIN. ${_maxRetries - _retryCount} attempt(s) left.'
            : '비밀번호가 틀렸어요. ${_maxRetries - _retryCount}회 남았어요.';
        _passcodeController.clear();
      });
      return;
    }
    widget.onUnlocked();
  }

  void _appendDigit(String digit) {
    if (_passcodeController.text.length >= 4) return;
    setState(() {
      _errorText = null;
      _passcodeController.text += digit;
    });
    if (_passcodeController.text.length == 4) _submitPasscode();
  }

  void _removeDigit() {
    if (_passcodeController.text.isEmpty) return;
    setState(() {
      _errorText = null;
      _passcodeController.text = _passcodeController.text
          .substring(0, _passcodeController.text.length - 1);
    });
  }

  Future<void> _tryBiometricUnlock({bool auto = false}) async {
    if (_isAuthenticating) return;
    if (auto && _hasAutoTriedBiometric) return;
    if (auto) _hasAutoTriedBiometric = true;
    setState(() => _isAuthenticating = true);

    try {
      final isSupported = await _localAuthentication.isDeviceSupported();
      final biometrics = await _localAuthentication.getAvailableBiometrics();
      if (!isSupported || biometrics.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorText = context.read<SettingsProvider>().isEnglish
              ? 'Biometric unlock not available.'
              : '이 기기에서 생체 인증을 사용할 수 없어요.';
        });
        return;
      }
      final didAuth = await _localAuthentication.authenticate(
        localizedReason: context.read<SettingsProvider>().isEnglish
            ? 'Authenticate to unlock the app.'
            : '앱 잠금을 해제하려면 생체 인증을 진행해 주세요.',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuth) widget.onUnlocked();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = context.read<SettingsProvider>().isEnglish
            ? 'Biometric authentication failed.'
            : '생체 인증에 실패했어요.';
      });
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _showRecoveryCodeDialog() async {
    final settings = context.read<SettingsProvider>();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => _RecoveryCodeUnlockDialog(isEnglish: settings.isEnglish),
    );
    if (!mounted || code == null) return;
    if (!settings.validateRecoveryCodeForUnlock(code)) {
      setState(() {
        _errorText = settings.isEnglish
            ? 'Recovery code does not match.'
            : '복구 코드가 일치하지 않아요.';
      });
      return;
    }
    await settings.disableAppLock();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.tr(
          '복구 코드로 잠금을 해제했어요. 앱 잠금이 해제되었어요.',
          'App lock removed using recovery code.',
        )),
      ));
    widget.onUnlocked();
  }
}

class _RecoveryCodeUnlockDialog extends StatefulWidget {
  const _RecoveryCodeUnlockDialog({required this.isEnglish});
  final bool isEnglish;

  @override
  State<_RecoveryCodeUnlockDialog> createState() =>
      _RecoveryCodeUnlockDialogState();
}

class _RecoveryCodeUnlockDialogState
    extends State<_RecoveryCodeUnlockDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.isEnglish ? 'Recovery code' : '복구 코드 확인',
        style: AppTextStyles.titleLarge.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEnglish
                ? 'Enter the recovery code you set during sign-up.'
                : '회원가입 때 설정한 복구 코드를 입력하세요.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: InputDecoration(
              hintText: widget.isEnglish
                  ? 'e.g. NDNY2026 (case-sensitive)'
                  : '예: NDNY2026 (영문/숫자, 대소문자 구분)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.isEnglish ? 'Cancel' : '취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.isEnglish ? 'Confirm' : '확인'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: 필요한 추가 imports**

`main.dart` 상단에:

```dart
import 'package:flutter/services.dart';
```

(이미 있으면 스킵 — `FilteringTextInputFormatter` 사용)

- [ ] **Step 4: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 5: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/main.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add _AppLockScreen with PIN retry limit and recovery code dialog"
```

---

### Task 10: MyApp → StatefulWidget으로 변환 + i18n + darkTheme

**Files:**
- Modify: `lib/main.dart`

현재 `MyApp`은 `StatelessWidget`. `_AppLockScreen`의 `requiresAppUnlock` 상태 관리, i18n delegate, darkTheme 분기를 위해 `StatefulWidget`으로 변환.

- [ ] **Step 1: import 추가**

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
```

- [ ] **Step 2: MyApp을 StatefulWidget으로 변환**

기존 `MyApp extends StatelessWidget` 전체를 아래로 교체:

```dart
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
            scrollBehavior: const _AppScrollBehavior(),
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
```

- [ ] **Step 3: _RootGate에 _AppLockScreen 삽입**

`_RootGateState`에 필드 추가:

```dart
bool _requiresAppUnlock = false;
```

기존 `_RootGateState.build()` 의 `switch (_stage)` 에서 `_Stage.main` 케이스를 수정:

```dart
// 기존
_Stage.main => const MainNavigationScreen(),

// 변경 후
_Stage.main => _requiresAppUnlock
    ? _AppLockScreen(
        onUnlocked: () {
          if (!mounted) return;
          setState(() => _requiresAppUnlock = false);
        },
      )
    : const MainNavigationScreen(),
```

**주의 — 타이밍 이슈:** `authStatus == authenticated` 시점에는 `SettingsProvider`가 아직
Supabase에서 사용자 데이터를 로드하기 전일 수 있어 `hasAppLock`이 false를 반환할 수 있음.
따라서 앱잠금 확인은 `_loadInitialData()` 완료 이후에 수행해야 함.

`_RootGateState.build()` 내 authenticated 감지 블록:

```dart
// 인증 감지: main stage로만 전환 (앱잠금 확인은 _loadInitialData에서)
if (authStatus == AuthStatus.authenticated && _stage != _Stage.main) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    setState(() => _stage = _Stage.main);
    // _requiresAppUnlock은 MainNavigationScreen의 _loadInitialData()에서 설정
  });
}
```

`_MainNavigationScreenState._loadInitialData()` 마지막에 앱잠금 확인 추가:

```dart
// _loadInitialData() 내 settingsProvider.load(user: authUser) 완료 후:
if (!mounted) return;
// 앱잠금 확인: 데이터 로드 완료 후 처리
final needsLock = settingsProvider.hasAppLock && settingsProvider.lockOnLaunch;
if (needsLock) {
  // _RootGate까지 올라가지 않고 MainNavigationScreen 내에서 처리하거나,
  // 별도 navigateToLock() 콜백을 MainNavigationScreen에 전달하는 방식 선택.
  // 단순 구현: _requiresAppUnlock은 _RootGate 상태이므로,
  // MainNavigationScreen이 생성되기 전인 _RootGate 수준에서 관리.
  // 대신 _loadInitialData 내에서 SettingsProvider.hasAppLock 체크 후
  // context를 통해 _RootGate 상태를 업데이트.
}
```

**실용적 구현:** `MainNavigationScreen`의 `initState`에서 `_loadInitialData()` 호출 후
부모 위젯(_RootGate)에 콜백으로 잠금 필요 여부를 전달하지 말고,
`MainNavigationScreen` 자체에서 오버레이 방식으로 처리:

```dart
// _MainNavigationScreenState에 추가
bool _isLocked = false;

@override
void initState() {
  super.initState();
  _currentIndex = 0; // startScreen은 데이터 로드 후 설정
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _loadInitialData();
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    if (settings.hasAppLock && settings.lockOnLaunch) {
      setState(() => _isLocked = true);
    }
  });
}
```

`MainNavigationScreen.build()` 의 `Scaffold` 반환 전에:

```dart
if (_isLocked) {
  return _AppLockScreen(
    onUnlocked: () => setState(() => _isLocked = false),
  );
}
// 기존 Scaffold(...) 반환
```

이렇게 하면 데이터 로드 완료 후 `hasAppLock`을 정확하게 읽을 수 있음.

- [ ] **Step 4: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 5: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/main.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add i18n delegates, darkTheme toggle, app lock gate in root"
```

---

### Task 11: MainNavigationScreen — 드래그 FAB 추가

**Files:**
- Modify: `lib/main.dart`

기존 `MainNavigationScreen`의 `Scaffold.body`를 `Stack` + 드래그 FAB 구조로 교체.

- [ ] **Step 1: transaction_entry_sheet import 확인**

`main.dart`에 이미 있는지 확인:

```dart
import 'screens/shared/transaction_entry_sheet.dart';
```

없으면 추가.

- [ ] **Step 2: _MainNavigationScreenState에 FAB 상태 필드 추가**

```dart
Offset? _fabOffset;
bool _isDraggingFab = false;
```

- [ ] **Step 3: Scaffold.body를 LayoutBuilder + Stack으로 교체**

기존 `Scaffold(body: IndexedStack(...), bottomNavigationBar: ...)` 의 `body` 부분을:

```dart
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

    final leftRail = railInset;
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
```

- [ ] **Step 4: BottomNavigationBar 높이 76으로 업데이트**

`SizedBox(height: 60, ...)` → `SizedBox(height: 76, ...)`, padding `vertical: 6` → `fromLTRB(0, 8, 0, 10)`.

- [ ] **Step 5: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 6: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/main.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add draggable FAB with rail snap to MainNavigationScreen"
```

---

## Chunk 3: Supabase + SettingsProvider

### Task 12: Supabase 마이그레이션 — app_lock 컬럼 추가

**Files:**
- Create: `supabase/migrations/20260506_add_app_lock_columns.sql`

> **스펙 vs 계획 차이:** 스펙은 `app_settings` 테이블을 언급했으나, 실제 코드베이스는
> 사용자 설정을 `public.users` 테이블에 저장하고 `AppUser` 모델로 읽는다.
> `AuthRepository.updateProfile()` → `toUpdateMap()` → `users` 테이블 경로를 따르므로
> 이 계획에서는 `public.users`에 컬럼을 추가한다.
> RLS 정책은 `public.users`의 기본키가 `id`이므로 `id = auth.uid()` 사용.

- [ ] **Step 1: 마이그레이션 파일 작성**

`/Volumes/ORICO/Money_Management/supabase/migrations/20260506_add_app_lock_columns.sql`:

```sql
-- 앱 잠금 PIN 해시 및 복구 코드 컬럼 추가
alter table public.users
  add column if not exists app_lock_passcode_hash text,
  add column if not exists app_lock_recovery_code text;

-- RLS: 기존 정책이 user_id = auth.uid() 기반이면 자동 커버됨.
-- 없는 경우를 대비한 조건부 생성.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where tablename = 'users' and policyname = 'users_own_row'
  ) then
    create policy "users_own_row" on public.users
      for all using (id = auth.uid());
  end if;
end $$;

-- 롤백: drop column if exists app_lock_passcode_hash, app_lock_recovery_code;
```

- [ ] **Step 2: Supabase에 적용**

```bash
cd /Volumes/ORICO/Money_Management && supabase db push
```

또는 Supabase 대시보드 SQL Editor에서 직접 실행.

- [ ] **Step 3: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add supabase/migrations/20260506_add_app_lock_columns.sql
git -C /Volumes/ORICO/Money_Management commit -m "feat: add app_lock_passcode_hash and app_lock_recovery_code columns to users"
```

---

### Task 13: AppUser 모델 — app_lock 필드 추가 + themeToken

**Files:**
- Modify: `lib/data/models/app_user.dart`

- [ ] **Step 1: 필드 추가**

`AppUser` 클래스에 필드 추가:

```dart
// 기존 biometricEnabled 아래에
final String? appLockPasscodeHash;
final String? appLockRecoveryCode;
```

- [ ] **Step 2: 생성자에 추가**

기존 `AppUser({...})` 생성자에서 `biometricEnabled` 파라미터 아래에 삽입.
`= null` 기본값을 반드시 지정해야 기존 callsite가 컴파일 오류를 내지 않음:

```dart
this.appLockPasscodeHash = null,
this.appLockRecoveryCode = null,
```

- [ ] **Step 3: fromMap에 추가**

```dart
appLockPasscodeHash: map['app_lock_passcode_hash'] as String?,
appLockRecoveryCode: map['app_lock_recovery_code'] as String?,
```

- [ ] **Step 4: toUpdateMap에 추가**

```dart
'app_lock_passcode_hash': appLockPasscodeHash,
'app_lock_recovery_code': appLockRecoveryCode,
```

- [ ] **Step 5: copyWith에 추가**

```dart
String? appLockPasscodeHash,
String? appLockRecoveryCode,
```

`return AppUser(...)` 내부:

```dart
appLockPasscodeHash: appLockPasscodeHash ?? this.appLockPasscodeHash,
appLockRecoveryCode: appLockRecoveryCode ?? this.appLockRecoveryCode,
```

- [ ] **Step 6: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 7: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/data/models/app_user.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add appLockPasscodeHash and appLockRecoveryCode to AppUser"
```

---

### Task 14: SettingsProvider — app lock 메서드 + locale + themeToken

**Files:**
- Modify: `lib/providers/settings_provider.dart`

- [ ] **Step 1: import 추가**

```dart
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' show Locale;
```

(`dart:convert`는 이미 있음. `crypto`와 `Locale` 추가)

- [ ] **Step 2: 인메모리 앱잠금 필드 추가**

`SettingsProvider` 클래스 상단에:

```dart
String? _pendingRecoveryCode;  // read-once
```

- [ ] **Step 3: themeToken getter 추가**

기존 `themeLabel` getter 아래에:

```dart
/// locale-independent token: 'light' | 'dark'
/// 기존 한국어 값('라이트'/'다크')도 처리.
String get themeToken {
  if (_themeLabel == '다크') return 'dark';
  if (_themeLabel == 'dark') return 'dark';
  return 'light';
}
```

- [ ] **Step 4: locale getter 추가**

`isEnglish` getter 아래에:

```dart
Locale get locale => Locale(_language == 'English' ? 'en' : 'ko');
```

- [ ] **Step 5: hasAppLock getter 추가**

```dart
bool get hasAppLock => _user?.appLockPasscodeHash?.isNotEmpty == true;
```

- [ ] **Step 6: recoveryCodeForDisplay getter 추가 (read-once)**

```dart
/// setAppLockPasscode() 직후 1회만 유효. 읽으면 즉시 null 처리.
/// ⚠️ 주의: 절대 build() 메서드나 Consumer/watch 콜백에서 호출하지 말 것.
/// 위젯 리빌드 시 중복 호출로 null이 반환될 수 있음.
/// 사용 패턴: setAppLockPasscode() 완료 후 then() 블록이나 await 다음에 1회 호출.
String? get recoveryCodeForDisplay {
  final code = _pendingRecoveryCode;
  _pendingRecoveryCode = null;
  return code;
}
```

- [ ] **Step 7: SHA-256 헬퍼 추가**

```dart
static String _sha256(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}
```

- [ ] **Step 8: setAppLockPasscode 추가**

```dart
Future<void> setAppLockPasscode(String passcode) {
  final recovery = _generateRecoveryCode();
  _pendingRecoveryCode = recovery;
  notifyListeners();
  return _queueWork(() async {
    final user = _user;
    final authRepository = _authRepository;
    if (user == null || authRepository == null) return;
    _user = await authRepository.updateProfile(
      user.copyWith(
        appLockPasscodeHash: _sha256(passcode),
        appLockRecoveryCode: _sha256(recovery),
      ),
    );
    notifyListeners();
  });
}

static String _generateRecoveryCode() {
  // Random.secure() 사용 — 시간 기반 modulo는 동일 값 반복으로 안전하지 않음
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = Random.secure();
  return List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
}
```

- [ ] **Step 9: validateAppLockPasscode 추가**

```dart
bool validateAppLockPasscode(String passcode) {
  final hash = _user?.appLockPasscodeHash;
  if (hash == null || hash.isEmpty) return false;
  return _sha256(passcode) == hash;
}
```

- [ ] **Step 10: validateRecoveryCodeForUnlock 추가**

```dart
bool validateRecoveryCodeForUnlock(String code) {
  final hash = _user?.appLockRecoveryCode;
  if (hash == null || hash.isEmpty) return false;
  return _sha256(code) == hash;
}
```

- [ ] **Step 11: disableAppLock 추가**

```dart
Future<void> disableAppLock() {
  return _queueWork(() async {
    final user = _user;
    final authRepository = _authRepository;
    if (user == null || authRepository == null) return;
    _user = await authRepository.updateProfile(
      user.copyWith(
        appLockPasscodeHash: '',
        appLockRecoveryCode: '',
        lockOnLaunch: false,
        biometricEnabled: false,
      ),
    );
    _lockOnLaunch = false;
    _biometric = false;
    notifyListeners();
  });
}
```

- [ ] **Step 12: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 13: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/providers/settings_provider.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add app lock methods, themeToken, locale getter to SettingsProvider"
```

---

## Chunk 4: NotificationService 연결

### Task 15: NotificationService 작성

**Files:**
- Create: `lib/services/notification_service.dart`

HB의 구현을 기반으로 Money_Management의 데이터 모델(`FixedExpense`, `NotificationSetting`)에 맞게 적응.

- [ ] **Step 1: notification_service.dart 작성**

`/Volumes/ORICO/Money_Management/lib/services/notification_service.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/fixed_expense.dart';
import '../data/models/notification_setting.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 100;
  static const String _channelId = 'integrated_expense_alerts';
  static const String _channelName = '통합 지출관리 알림';
  static const String _channelDescription = '리마인더와 고정지출 알림';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macImpl = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await androidImpl?.requestNotificationsPermission() ?? true;
    final iosGranted =
        await iosImpl?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
    final macGranted =
        await macImpl?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;

    return androidGranted && iosGranted && macGranted;
  }

  /// Supabase에서 가져온 설정과 고정지출 목록으로 로컬 알림 전체 재예약.
  Future<void> syncSchedules({
    required NotificationSetting setting,
    required List<FixedExpense> activeFixedExpenses,
    required bool isEnglish,
  }) async {
    await initialize();
    await _plugin.cancelAll();

    if (setting.dailySummaryEnabled) {
      await _scheduleDailyReminder(
        time: setting.dailySummaryTime, // 'HH:mm'
        isEnglish: isEnglish,
      );
    }

    if (setting.fixedExpenseAlertEnabled) {
      await _scheduleFixedExpenseAlerts(
        expenses: activeFixedExpenses,
        isEnglish: isEnglish,
      );
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> _scheduleDailyReminder({
    required String time,
    required bool isEnglish,
  }) async {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 21;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    await _plugin.zonedSchedule(
      _dailyReminderId,
      isEnglish ? 'Daily entry reminder' : '오늘 기록을 남겨보세요',
      isEnglish
          ? 'Add today\'s income or expense before the day ends.'
          : '하루가 끝나기 전에 오늘의 입출금 내역을 기록해 주세요.',
      _nextInstanceOfTime(hour: hour, minute: minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleFixedExpenseAlerts({
    required List<FixedExpense> expenses,
    required bool isEnglish,
  }) async {
    var id = 1000;
    for (final expense in expenses.where((e) => e.isActive && e.isMonthly)) {
      for (var monthOffset = 0; monthOffset < 6; monthOffset++) {
        try {
          final scheduledDate = _fixedExpenseAlertDate(
            dueDay: expense.billingDay,
            monthOffset: monthOffset,
          );
          if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) continue;

          await _plugin.zonedSchedule(
            id++,
            isEnglish ? 'Upcoming fixed expense' : '고정지출 예정 알림',
            isEnglish
                ? '${expense.title} will be deducted tomorrow.'
                : '${expense.title} 항목이 내일 자동 반영될 예정이에요.',
            scheduledDate,
            _notificationDetails(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('[NotificationService] Failed to schedule ${expense.title}: $e');
        }
      }
    }
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _fixedExpenseAlertDate({
    required int dueDay,
    required int monthOffset,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final targetMonth =
        tz.TZDateTime(tz.local, now.year, now.month + monthOffset, 1);
    final lastDay = tz.TZDateTime(
      tz.local,
      targetMonth.year,
      targetMonth.month + 1,
      0,
    ).day;
    final normalizedDay = dueDay.clamp(1, lastDay);
    final dueDate = tz.TZDateTime(
      tz.local,
      targetMonth.year,
      targetMonth.month,
      normalizedDay,
      9,
    );
    return dueDate.subtract(const Duration(days: 1));
  }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 3: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/services/notification_service.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: add NotificationService bridging Supabase rules to local notifications"
```

---

### Task 16: NotificationService를 main.dart에 연결

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: import 추가**

```dart
import 'services/notification_service.dart';
```

- [ ] **Step 2: _loadInitialData()에 알림 초기화 추가**

기존 `_loadInitialData()` 에서 `settingsProvider.load(user: authUser)` 완료 후:

```dart
// 알림 서비스 초기화 및 예약 (권한 없으면 조용히 스킵)
final notificationService = NotificationService.instance;
await notificationService.initialize();
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
```

- [ ] **Step 3: SettingsProvider에 notificationSetting getter 노출**

`lib/providers/settings_provider.dart` 에 getter 추가:

```dart
NotificationSetting? get notificationSetting => _notificationSetting;
```

- [ ] **Step 4: FixedExpenseProvider에 items getter 확인**

`lib/providers/fixed_expense_provider.dart` 에 `items` getter가 있는지 확인. 없으면 추가:

```bash
grep -n "get items\|List.*fixed" /Volumes/ORICO/Money_Management/lib/providers/fixed_expense_provider.dart | head -10
```

- [ ] **Step 5: 빌드 확인**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze --no-fatal-infos 2>&1 | tail -5
```

- [ ] **Step 6: 커밋**

```bash
git -C /Volumes/ORICO/Money_Management add lib/main.dart lib/providers/settings_provider.dart
git -C /Volumes/ORICO/Money_Management commit -m "feat: wire NotificationService into app initialization flow"
```

---

## 최종 검증

- [ ] **전체 정적 분석**

```bash
cd /Volumes/ORICO/Money_Management && flutter analyze 2>&1
```

예상: 0 errors.

- [ ] **테스트 실행**

```bash
cd /Volumes/ORICO/Money_Management && flutter test 2>&1
```

- [ ] **iOS 빌드 확인 (시뮬레이터)**

```bash
cd /Volumes/ORICO/Money_Management && flutter build ios --debug --no-codesign 2>&1 | tail -10
```

- [ ] **수동 확인 체크리스트**
  - [ ] 라이트/다크 테마 전환
  - [ ] 한/영 언어 전환 + UI 텍스트 변경
  - [ ] 런치 로딩 스크린 애니메이션
  - [ ] 드래그 FAB 이동 + rail snap
  - [ ] 앱 잠금 설정 → 복구 코드 1회 표시
  - [ ] PIN 5회 실패 → 복구 코드 다이얼로그 전환
  - [ ] 생체인증 잠금 해제
  - [ ] 오프라인 시 로그인 화면 리다이렉트
  - [ ] 알림 권한 허용 후 고정지출 알림 예약 확인
