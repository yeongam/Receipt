# 통합 지출관리

Flutter + Supabase 기반 개인 가계부 앱 — 텐텐 팀 프로젝트

---

## 주요 기능

| 화면 | 기능 |
|------|------|
| 홈 | 월별 수입/지출 요약, 최근 거래 내역 |
| 내역 | 전체 거래 목록, 날짜/카테고리 필터 |
| 리포트 | 도넛/바 차트 기반 지출 분석 |
| 알림 | 로컬 푸시 알림 설정 |
| 마이페이지 | 프로필 관리, 비밀번호 재설정 |
| 설정 | 앱 잠금(생체인증), 테마, 언어 |

---

## 기술 스택

| 분류 | 기술 |
|------|------|
| 프레임워크 | Flutter ≥ 3.38.4 |
| 백엔드 | Supabase (PostgreSQL + Auth + Edge Functions) |
| 상태관리 | Provider |
| 차트 | fl_chart |
| 보안 | flutter_secure_storage, local_auth, crypto |
| 알림 | flutter_local_notifications, timezone |

---

## 프로젝트 구조

```
lib/
├── core/           # 공통 상수, 테마, 유틸리티
├── data/           # 모델, 레포지토리
├── providers/      # 상태 관리
├── screens/
│   ├── auth/       # 로그인, 회원가입
│   ├── home/       # 홈 대시보드
│   ├── history/    # 거래 내역
│   ├── report/     # 지출 리포트
│   ├── mypage/     # 마이페이지
│   ├── notification/ # 알림
│   ├── settings/   # 앱 설정
│   ├── intro/      # 온보딩
│   └── shared/     # 공통 위젯
├── services/       # API, 인증 서비스
└── main.dart
```

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
팀장에게 실제 값을 받아 프로젝트 루트에 아래 형식으로 생성하세요.

```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

> `.env` 파일은 git에 포함되지 않으므로 직접 생성해야 합니다.

### 3단계 — 실행

**터미널:**

```bash
flutter run --dart-define-from-file=.env
```

**VS Code:** `.vscode/launch.json`이 이미 설정되어 있으므로 F5(Run)로 바로 실행할 수 있습니다.

**Android Studio / IntelliJ:** Run Configuration → Additional run args에 `--dart-define-from-file=.env` 추가.

---

## Supabase 프로젝트 신규 구성 (팀장 전용)

기존 프로젝트를 공유하는 팀원은 이 섹션이 필요하지 않습니다.

### DB 마이그레이션

Supabase 대시보드 → SQL Editor에서 아래 파일을 순서대로 실행:

```
supabase/migrations/20260429000000_initial_schema.sql
supabase/migrations/20260429100000_persist_app_settings.sql
supabase/migrations/20260506000000_add_app_lock_columns.sql
supabase/migrations/20260506100000_add_transactions_index.sql
supabase/migrations/20260513000000_add_category_index.sql
supabase/migrations/20260513100100_password_reset_rate_limit.sql
supabase/migrations/20260513100200_recovery_code_rpc.sql
supabase/migrations/20260513100300_username_auth.sql
supabase/migrations/20260513200000_add_missing_columns.sql
supabase/migrations/20260513300000_add_user_id_indexes.sql
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

---

## Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/yeongam">
        <img src="https://github.com/yeongam.png" width="72" /><br />
        <sub><b>yeongam</b></sub>
      </a>
    </td>
  </tr>
</table>
