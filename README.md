# Receipt - 가계부 앱

Flutter로 개발된 개인 가계부 애플리케이션입니다.

## 주요 기능

- **거래 내역 관리**: 수입/지출 내역을 쉽게 기록하고 조회
- **예산 설정**: 카테고리별 예산 설정 및 사용 현황 추적
- **고정 지출 관리**: 반복되는 고정 지출 항목 관리
- **리포트**: 월별/카테고리별 지출 현황 분석
- **알림 설정**: 예산 초과 등 맞춤 알림 규칙 설정
- **보안**: PIN 잠금 및 앱 잠금 기능
- **다국어 지원**: 로케일 설정 지원

## 기술 스택

- **프레임워크**: Flutter
- **백엔드**: Supabase (인증 및 데이터베이스)
- **상태 관리**: Provider

## 시작하기

### 사전 요구사항

- Flutter SDK 설치
- Dart SDK
- Android Studio 또는 Xcode (플랫폼에 따라)

### 설치 방법

1. 저장소 클론

```bash
git clone https://github.com/yeongam/receipt.git
cd receipt
```

2. 패키지 설치

```bash
flutter pub get
```

3. Supabase 설정

`lib/core/supabase/supabase_config.dart` 파일에 Supabase URL과 API 키를 설정합니다.

4. 앱 실행

```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── core/          # 공통 유틸리티, 테마, 설정
├── data/          # 데이터 모델 및 리포지토리
├── providers/     # 상태 관리 (Provider)
├── screens/       # UI 화면
│   ├── auth/      # 로그인/회원가입
│   ├── home/      # 홈 화면
│   ├── history/   # 거래 내역
│   ├── report/    # 리포트
│   ├── settings/  # 설정
│   └── mypage/    # 마이페이지
└── services/      # 알림 등 서비스
```

## Flutter 관련 리소스

- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Flutter 시작하기](https://docs.flutter.dev/get-started/learn-flutter)
- [첫 Flutter 앱 만들기](https://docs.flutter.dev/get-started/codelab)
