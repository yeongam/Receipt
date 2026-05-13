# 통합 지출관리

Flutter + Supabase 기반 개인 가계부 앱.

---

## 팀원 세팅 가이드

### 사전 요구사항

| 도구 | 버전 |
|------|------|
| Flutter SDK | 3.38.4 이상 |
| Xcode | iOS 빌드 시 필요 |
| Android Studio / JDK | Android 빌드 시 필요 |

### 1단계 — 레포 클론 및 패키지 설치

```bash
git clone https://github.com/yeongam/Receipt.git
cd Receipt
flutter pub get
```

iOS 빌드 시 CocoaPods 추가 설치:

```bash
cd ios && pod install && cd ..
```

### 2단계 — 환경 변수 설정

Supabase 키는 소스에 포함되지 않으므로 로컬에 `.env` 파일이 필요합니다.
팀장에게 실제 값을 받아 아래와 같이 설정하세요.

```bash
cp .env.example .env
# .env 파일을 열고 실제 SUPABASE_URL, SUPABASE_ANON_KEY 입력
```

> 같은 Supabase 프로젝트를 공유하는 경우, 값은 팀 내 공유 채널(Slack, 노션 등)에서 받으세요.
> `.env` 파일은 git에 포함되지 않으므로 직접 생성해야 합니다.

### 3단계 — 실행

```bash
flutter run --dart-define-from-file=.env
```

IDE(VS Code / Android Studio)에서 실행 시 `--dart-define-from-file=.env` 인수를 launch 설정에 추가하세요.

---

## Supabase 프로젝트 신규 구성 (팀장 전용)

기존 프로젝트를 공유하는 팀원은 이 섹션이 필요하지 않습니다.

### DB 마이그레이션

Supabase 대시보드 → SQL Editor에서 아래 파일을 순서대로 실행:

```
supabase/migrations/20260429000000_initial_schema.sql
supabase/migrations/20260429100000_persist_app_settings.sql
supabase/migrations/20260506_add_app_lock_columns.sql
supabase/migrations/20260506_add_transactions_index.sql
supabase/migrations/20260513_add_category_index.sql
supabase/migrations/20260513_recovery_code_rpc.sql
supabase/migrations/20260513_username_auth.sql
```

### Edge Function 배포

```bash
# Supabase CLI 필요
supabase functions deploy reset-password-with-recovery-code

# 서비스 롤 키 등록 (서버 전용 — 클라이언트에 노출 금지)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

---

## 빌드 및 배포

```bash
# Android
flutter build apk --dart-define-from-file=.env

# iOS
flutter build ipa --dart-define-from-file=.env
```

---

## 보안 참고사항

- `SUPABASE_ANON_KEY`는 클라이언트 공개 키입니다. 데이터 보호는 Supabase RLS 정책으로 처리합니다.
- `SUPABASE_SERVICE_ROLE_KEY`는 Edge Function 서버 측에서만 사용하며, 절대 클라이언트 코드에 포함하지 마세요.
- `.env` 파일은 `.gitignore`에 등록되어 있습니다. 커밋하지 마세요.
