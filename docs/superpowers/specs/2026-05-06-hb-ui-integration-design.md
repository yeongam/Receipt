# HB UI 통합 설계 문서

**날짜**: 2026-05-06
**프로젝트**: Money_Management (Supabase 백엔드 기반)
**목표**: HB 프로젝트의 UI 구조를 Money_Management에 통합

---

## 1. 개요

Money_Management의 Supabase 백엔드를 유지하면서 HB 프로젝트의 UI 개선 사항 전체를 이식한다. 충돌 발생 시 항상 Supabase 패턴으로 변환한다.

---

## 2. 통합 범위

### HB에서 가져오는 UI 기능

| 기능 | 파일/위치 |
|---|---|
| 다크테마 | `core/theme/` 전체 교체 |
| 한/영 i18n | `context.tr()` 확장 + `flutter_localizations` |
| 드래그 가능한 FAB | `main.dart` > `MainNavigationScreen` |
| 앱 잠금 (PIN + 생체인증) | `main.dart` > `_AppLockScreen` (Supabase 변환) |
| 런치 로딩 스크린 | `main.dart` > `_LaunchLoadingScreen` |
| BouncingScrollPhysics | `main.dart` > `_AppScrollBehavior` |
| Edge overscroll | `screens/shared/edge_overscroll_background.dart` |
| 텍스트 스케일 고정 | `main.dart` > `MediaQuery` builder |
| PinPad 위젯 | `screens/shared/pin_pad.dart` |
| 알림 서비스 | `services/notification_service.dart` |

---

## 3. 아키텍처

### 레이어 순서 (B방식: 레이어 순차 통합)

```
Layer 1: pubspec.yaml 의존성 추가
Layer 2: core/theme/ 교체 (다크테마)
Layer 3: screens/shared/ 위젯 추가
Layer 4: main.dart 재구성
Layer 5: Supabase 변환 (앱잠금 + locale + theme 설정)
Layer 6: 알림 서비스 브리지 연결
```

### 충돌 해소 원칙

| HB 패턴 | 변환 방향 |
|---|---|
| `SharedPreferences` 앱잠금 PIN 저장 | Supabase `app_settings` 테이블 |
| `SharedPreferences` locale 저장 | Supabase `app_settings` 테이블 |
| `AppDependencies` 로컬 DI 패턴 | Money_Management `MultiProvider` 유지 |
| 로컬 알림 규칙 정의 | Supabase `notification_rule`에서 읽어 로컬 예약 |
| `'다크'` 문자열 테마 구분자 | locale-independent 토큰 `'dark'` / `'light'`로 저장 |

---

## 4. 세부 변경 내용

### Layer 1 — pubspec.yaml

추가 의존성:
```yaml
flutter_localizations:
  sdk: flutter
local_auth: ^2.3.0
crypto: ^3.0.6
flutter_local_notifications: ^19.4.2
flutter_timezone: ^4.1.1
timezone: ^0.10.1
```

### Layer 2 — core/theme/ 교체

HB의 3개 파일(`app_colors.dart`, `app_text_styles.dart`, `app_theme.dart`)로 교체:
- `AppColors`에 다크 색상 상수 추가 (`darkBackground`, `darkTextPrimary`, `darkSurfaceAlt` 등)
- `AppTheme.darkTheme` 추가
- `AppTextStyles` 확장 (`navLabel`, `navLabelSelected`, `displayLarge`, `headlineMedium` 등)

### Layer 3 — screens/shared/ 위젯 추가

HB에서 복사:
- `pin_pad.dart` → `PinDots`, `NumericPinPad` 위젯
- `edge_overscroll_background.dart` → 스크롤 오버 시 배경 효과

### Layer 4 — main.dart 재구성

HB의 main.dart 구조를 기반으로 Supabase 인증 흐름 유지:

**앱 시작 흐름:**
```
Supabase.initialize()
  → _LaunchLoadingScreen (애니메이션, 최소 노출)
  → Supabase 세션 확인 + app_settings 로드 시도
  → [오프라인/세션 만료 시] → 오프라인 처리 (Layer 5-5 참조)
  → 앱잠금 활성화 여부 확인 (lock_on_launch)
  → _AppLockScreen (필요 시)
  → MainNavigationScreen
```

**추가 요소:**
- `_LaunchLoadingScreen`: 로고 + 프로그레스바 애니메이션
- `_AppScrollBehavior`: BouncingScrollPhysics 전역 적용
- `_AppLockScreen`: PIN/생체인증 (Supabase 저장)
- 드래그 FAB: `MainNavigationScreen` 내 `Stack` 구조
- i18n delegates: `GlobalMaterialLocalizations` 등 3개
- `textScaler: TextScaler.noScaling` 전역 적용 (의도적 결정 — 아래 4-1 참조)
- `darkTheme` 분기: `settings.themeToken == 'dark'` 조건

#### 4-1. textScaler.noScaling 의도적 결정

시스템 폰트 크기 변경을 무시하는 것은 WCAG 1.4.4 기준에서 권장되지 않는다.
그러나 이 앱은 금액/숫자 레이아웃이 시스템 폰트 확대 시 깨지는 문제가 있어,
**의도적으로 텍스트 스케일을 고정**한다. 향후 반응형 레이아웃 개선 후 제거 예정.

### Layer 5 — Supabase 변환

#### 5-1. app_settings 테이블 신규 컬럼

기존 `app_settings` 테이블에 컬럼 추가 (신규 테이블 아님):
```sql
ALTER TABLE app_settings
  ADD COLUMN IF NOT EXISTS app_lock_passcode_hash  text,
  ADD COLUMN IF NOT EXISTS lock_on_launch          boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS biometric_enabled       boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS app_lock_recovery_code  text,
  ADD COLUMN IF NOT EXISTS locale                  text    NOT NULL DEFAULT 'ko',
  ADD COLUMN IF NOT EXISTS theme_token             text    NOT NULL DEFAULT 'light';
```

**테마 토큰**: `'light'` / `'dark'` (locale-independent). UI 표시만 한/영 번역.

`supabase/migrations/20260506_add_app_settings_columns.sql` 파일의 내용은
위 `ALTER TABLE` 구문과 아래 5-2의 RLS 정책 구문을 그대로 포함한다.
롤백: `DROP COLUMN IF EXISTS`로 각 컬럼 제거.

#### 5-2. RLS (Row Level Security) 정책

기존 `app_settings` RLS 정책이 `user_id = auth.uid()` 기반이면 기존 정책으로 커버됨.
미확인 시 마이그레이션에 명시적 추가:
```sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'app_settings' AND policyname = 'user_own_settings'
  ) THEN
    CREATE POLICY "user_own_settings" ON app_settings
      FOR ALL USING (user_id = auth.uid());
  END IF;
END $$;
```

`app_lock_passcode_hash`, `app_lock_recovery_code`는 **항상 SHA-256 해시 상태로만 저장**,
평문 절대 저장 금지.

#### 5-3. 앱잠금 설정 흐름

```
사용자가 앱잠금 설정 시:
1. 4자리 PIN 입력
2. 복구 코드 자동 생성 (UUID v4 기반 영문+숫자 12자)
3. 복구 코드를 사용자에게 1회 표시 (다이얼로그 내 복사 버튼 제공)
4. PIN → SHA-256 해시 / 복구 코드 → SHA-256 해시
5. Supabase app_settings에 저장
6. SettingsProvider 내 _pendingRecoveryCode 인메모리 필드 null 처리
```

#### 5-4. SettingsProvider 추가 메서드

```dart
// 앱잠금
Future<void> setAppLockPasscode(String passcode)
  // 내부: 복구 코드 생성 → _pendingRecoveryCode에 임시 보관 → 해시 후 Supabase 저장
bool validateAppLockPasscode(String passcode)
bool validateRecoveryCodeForUnlock(String code)
  // 반환값만 bool. 잠금 해제(disableAppLock) 호출은 호출자(UI) 책임
Future<void> disableAppLock()
bool get hasAppLock
bool get lockOnLaunch
bool get biometric

// recoveryCodeForDisplay: setAppLockPasscode() 직후 1회만 유효
// 내부적으로 String? _pendingRecoveryCode 필드 사용
// get 호출 시 값을 반환하고 즉시 null로 초기화 (read-once 패턴)
String? get recoveryCodeForDisplay

// 테마/로케일
Future<void> setTheme(String token)   // 'light' | 'dark'
Future<void> setLocale(String locale) // 'ko' | 'en'
String get themeToken
Locale get locale
```

**기존 필드 마이그레이션:**
- `SettingsProvider`에 `themeLabel`(한국어 문자열) 필드가 있으면:
  - 기존 값 `'라이트'` → `'light'`, `'다크'` → `'dark'` 변환 후 Supabase 저장
  - 기존 컬럼/필드 제거
- `locale` 관련 기존 필드가 있으면 동일하게 Supabase로 마이그레이션 후 제거

#### 5-5. PIN 재시도 제한 및 잠금 정책

- 최대 시도 횟수: **5회**
- 5회 초과 시: PIN 입력 비활성화 + 복구 코드 입력 화면으로 전환
- 복구 코드 사용 시: `validateRecoveryCodeForUnlock()` 검증 → 성공 시 UI에서 `disableAppLock()` 호출 → 앱잠금 해제 및 설정 비활성화
- 재시도 카운트는 인메모리(세션 내)에만 유지. 앱 재시작 시 초기화.

#### 5-6. 오프라인 / 세션 만료 처리

앱 시작 시 `app_settings` 조회 실패(오프라인, 세션 만료):
- **정책**: 로그인 화면으로 리다이렉트 (앱잠금 우회 방지)
- Supabase 세션 만료: 자동 갱신 실패 시 `AuthStatus.unauthenticated` 처리 (기존 `_RootGate` 로직 활용)
- 오프라인 상태: 로딩 화면에서 오류 스낵바 + 재시도 버튼 표시
- **앱잠금 상태를 로컬에 캐시하지 않음** — Supabase 접근 불가 시 항상 로그인 요구

### Layer 6 — 알림 서비스 브리지

#### 6-1. NotificationRule 모델 (기존 파일 수정)

`lib/data/models/notification_rule.dart` — 기존 Money_Management 파일:
```dart
class NotificationRule {
  final String id;
  final String userId;
  final String title;       // 알림 제목
  final String body;        // 알림 본문
  final String time;        // "HH:mm" 형식 문자열 (Supabase text 컬럼)
  final List<int> weekdays; // 요일 (1=월 ~ 7=일), 빈 리스트 = 매일
  final bool isEnabled;

  TimeOfDay get timeOfDay {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
```

**Supabase `notification_rule` 테이블 스키마:**
```sql
id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
user_id    uuid REFERENCES auth.users NOT NULL,
title      text NOT NULL,
body       text NOT NULL,
time       text NOT NULL,  -- "HH:mm" 형식
weekdays   int[] NOT NULL DEFAULT '{}',  -- 빈 배열 = 매일
is_enabled boolean NOT NULL DEFAULT true
```

`notification_repository.dart` — 기존 파일. `getAll(String userId)` 메서드 없으면 추가:
```dart
Future<List<NotificationRule>> getAll(String userId)
```

#### 6-2. NotificationService (신규)

`lib/services/notification_service.dart`:
```dart
class NotificationService {
  Future<void> initialize()                                    // timezone + 플러그인 초기화
  Future<bool> requestPermission()                             // 권한 요청, bool 반환
  Future<void> scheduleFromRules(List<NotificationRule> rules) // cancelAll() 후 재예약
  Future<void> cancelAll()
}
```

**`scheduleFromRules` 오류 처리:**
- 예약 실패(권한 취소, 플러그인 오류): try-catch로 포착, `debugPrint`로 로그, 조용히 스킵
- 앱을 크래시시키지 않음. 실패한 rule만 건너뜀.

**앱 시작 시 연결 흐름:**
```
_loadInitialData() 내부:
  await NotificationService.initialize()
  final granted = await NotificationService.requestPermission()
  if (!granted) return;  // 권한 없으면 스킵
  final rules = await NotificationRepository.getAll(userId)
  await NotificationService.scheduleFromRules(rules)
```

알림 규칙 변경(추가/수정/삭제) 시: `scheduleFromRules` 재호출로 전체 재예약.

---

## 5. 파일 변경 목록

### 수정 파일
- `pubspec.yaml`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_theme.dart`
- `lib/main.dart`
- `lib/providers/settings_provider.dart`
- `lib/data/models/notification_rule.dart`
- `lib/data/repositories/notification_repository.dart`

### 신규 파일
- `lib/screens/shared/pin_pad.dart`
- `lib/screens/shared/edge_overscroll_background.dart`
- `lib/services/notification_service.dart`

### Supabase 마이그레이션
- `supabase/migrations/20260506_add_app_settings_columns.sql`
  - 내용: 5-1의 `ALTER TABLE` + 5-2의 RLS 정책 조건부 생성

---

## 6. 테스트 계획

### 정상 경로
- [ ] 라이트/다크 테마 전환 → Supabase 저장 → 재시작 후 복원
- [ ] 한/영 언어 전환 → Supabase 저장 → 재시작 후 복원
- [ ] 앱 잠금 설정 → 복구 코드 1회 표시 → Supabase 저장 확인
- [ ] 올바른 PIN 입력 후 잠금 해제
- [ ] 생체인증 잠금 해제 (Face ID / Touch ID)
- [ ] 복구 코드 검증 → UI에서 `disableAppLock()` 호출 → 잠금 해제 및 비활성화
- [ ] 드래그 FAB 이동 및 좌/우 rail snap 확인
- [ ] 로딩 스크린 애니메이션 완료 후 전환
- [ ] 알림 규칙 → 로컬 알림 예약 → 정시 발송 확인

### 예외/오류 경로
- [ ] 잘못된 PIN 4회 입력 → 오류 메시지 표시
- [ ] 잘못된 PIN 5회 입력 → 복구 코드 입력 화면 전환
- [ ] `recoveryCodeForDisplay` 두 번째 접근 → null 반환 확인
- [ ] 생체인증 불가 기기 → PIN 폴백 자동 표시
- [ ] 알림 권한 미허용 → 스킵, 알림 설정 화면에서 재유도
- [ ] `scheduleFromRules` 중 일부 rule 예약 실패 → 앱 크래시 없이 스킵
- [ ] 오프라인 상태 앱 시작 → 로그인 화면으로 리다이렉트
- [ ] Supabase 세션 만료 → 로그인 화면으로 리다이렉트
- [ ] 테마/로케일 콜드 리스타트 후 유지 여부
- [ ] `textScaler: noScaling` 적용 확인 (시스템 폰트 크기 변경 무시)
