<div align="center">

# 🧾 Receipt

**똑똑한 소비의 시작, 통합 지출관리 가계부**

<br>

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
<img src="https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase">
<img src="https://img.shields.io/badge/Provider-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white" alt="Provider">

<img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
<img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white" alt="iOS">

</div>

<br>

---

## 📌 프로젝트 소개

**Receipt**는 흩어져 있는 수입과 지출을 한 곳에서 관리할 수 있도록 도와주는 **통합 지출관리 가계부 애플리케이션**입니다.

매일의 소비를 기록하는 것에서 그치지 않고, 카테고리별 예산 관리와 시각화된 리포트를 통해 **나의 소비 패턴을 한눈에 파악**하고 더 나은 소비 습관을 만들어 갈 수 있도록 설계되었습니다.

Flutter 기반으로 개발되어 Android와 iOS에서 동일한 경험을 제공하며, Supabase를 통한 안전한 데이터 동기화를 지원합니다.

<br>

## ✨ 주요 기능

### 💸 거래 내역 관리
수입과 지출을 간편하게 기록하고, 날짜·카테고리별로 내역을 조회할 수 있습니다. 빠른 입력 시트를 통해 몇 번의 터치만으로 거래를 등록할 수 있습니다.

### 📊 리포트 & 소비 분석
도넛 차트와 바 차트로 월별·카테고리별 지출 현황을 시각화하여, 내 소비 패턴을 직관적으로 분석할 수 있습니다.

### 🎯 예산 관리
카테고리별 예산을 설정하고 사용 현황을 추적합니다. 예산 초과가 임박하면 알림으로 미리 알려줍니다.

### 🔁 고정 지출 관리
구독료, 월세, 통신비 등 매달 반복되는 고정 지출을 등록하여 빠뜨리지 않고 관리할 수 있습니다.

### 🔔 맞춤 알림
예산 초과, 고정 지출일 등 원하는 조건에 맞춰 알림 규칙을 직접 설정할 수 있습니다.

### 🔐 보안 & 개인정보 보호
PIN 잠금과 생체 인증(지문/Face ID)을 지원하여 민감한 금융 정보를 안전하게 보호합니다.

### 🌏 다국어 & 로케일 지원
언어 및 통화 형식 설정을 지원하여 사용 환경에 맞게 커스터마이징할 수 있습니다.

<br>

## 🛠 기술 스택

| 분류 | 기술 |
|------|------|
| **프레임워크** | Flutter (Dart) |
| **백엔드 / DB** | Supabase |
| **상태 관리** | Provider |
| **차트** | fl_chart |
| **보안** | flutter_secure_storage, local_auth, crypto |
| **알림** | flutter_local_notifications, timezone |

<br>

## 📂 프로젝트 구조

```
lib/
├── core/          # 테마, 인증, Supabase 설정, 공통 유틸리티
├── data/
│   ├── models/    # 거래, 예산, 카테고리 등 데이터 모델
│   └── repositories/  # 데이터 접근 계층
├── providers/     # Provider 기반 상태 관리
├── screens/       # UI 화면
│   ├── auth/      # 로그인 · 회원가입 · 앱 잠금
│   ├── home/      # 홈
│   ├── history/   # 거래 내역
│   ├── report/    # 소비 리포트
│   ├── settings/  # 예산 · 카테고리 · 보안 등 설정
│   └── mypage/    # 마이페이지
└── services/      # 로컬 알림 서비스
```

<br>

## 🚀 시작하기

```bash
# 1. 저장소 클론
git clone https://github.com/yeongam/Receipt.git
cd Receipt

# 2. 의존성 설치
flutter pub get

# 3. 앱 실행
flutter run
```

> Supabase 연동을 위해 `lib/core/supabase/supabase_config.dart`에 프로젝트 URL과 API 키 설정이 필요합니다.

<br>

---

<div align="center">

**텐텐 팀 프로젝트** 🍀

</div>
