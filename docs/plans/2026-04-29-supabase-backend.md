# Supabase Backend Implementation Plan

> **For agentic workers:** Use `executing-plans` skill to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** app_001의 인메모리 데이터를 Supabase (PostgreSQL + Auth)로 전환하여 실제 백엔드를 구축한다.

**Architecture:**
- Supabase Auth (email/password)로 인증 처리
- Supabase PostgreSQL에 DB 설계서 기준 8개 테이블 구성 (Row Level Security 적용)
- Repository 패턴으로 Supabase 클라이언트를 캡슐화, Provider가 Repository를 통해 상태 관리

**Tech Stack:** Flutter, supabase_flutter ^2.x, provider ^6.x

---

## 파일 구조 (생성/수정 목록)

### 생성 (New)
```
supabase/migrations/20260429000000_initial_schema.sql   ← DB 스키마 전체
lib/core/supabase/supabase_config.dart                  ← 클라이언트 싱글턴
lib/data/models/app_user.dart                           ← 사용자 프로필 모델
lib/data/models/category.dart                           ← 카테고리 모델 (UUID)
lib/data/models/fixed_expense.dart                      ← 고정지출 모델
lib/data/models/budget.dart                             ← 예산 모델
lib/data/models/budget_category.dart                    ← 카테고리별 예산 모델
lib/data/models/notification_setting.dart               ← 알림 설정 모델
lib/data/models/notification_rule.dart                  ← 알림 규칙 모델
lib/data/repositories/auth_repository.dart              ← 로그인/회원가입/로그아웃
lib/data/repositories/category_repository.dart          ← 카테고리 CRUD
lib/data/repositories/transaction_repository.dart       ← 거래내역 CRUD + 통계
lib/data/repositories/fixed_expense_repository.dart     ← 고정지출 CRUD
lib/data/repositories/budget_repository.dart            ← 예산 CRUD
lib/data/repositories/notification_repository.dart      ← 알림설정/규칙 CRUD
lib/providers/auth_provider.dart                        ← 인증 상태 관리
lib/providers/category_provider.dart                    ← 카테고리 상태 관리
lib/providers/fixed_expense_provider.dart               ← 고정지출 상태 관리
lib/providers/budget_provider.dart                      ← 예산 상태 관리
```

### 수정 (Modify)
```
pubspec.yaml                                            ← sqflite→supabase_flutter
lib/main.dart                                           ← Supabase init + Provider 등록
lib/data/models/transaction.dart                        ← UUID, 필드 전면 교체
lib/providers/transaction_provider.dart                 ← in-memory→Repository 기반
lib/screens/auth/login_screen.dart                      ← 실제 Supabase Auth 연동
lib/screens/auth/signup_screen.dart                     ← 실제 Supabase Auth 연동
lib/screens/home/home_screen.dart                       ← 현재 월 동적 처리
```

---

## Chunk 1: 기반 구축 (Schema + Supabase 설정 + 모델)

### Task 1: Supabase 마이그레이션 SQL 작성

**Files:**
- Create: `supabase/migrations/20260429000000_initial_schema.sql`

- [ ] **Step 1: SQL 파일 생성**

```sql
-- ============================================================
-- 통합 지출관리 Initial Schema
-- 2026-04-29
-- ============================================================

-- ─── users (auth.users 확장 프로필) ──────────────────────────
create table public.users (
  id                  uuid        primary key references auth.users(id) on delete cascade,
  email               text        not null unique,
  name                text        not null default '',
  monthly_income      integer     not null default 0,
  currency            text        not null default 'KRW',
  is_profile_completed boolean    not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ─── categories ──────────────────────────────────────────────
create table public.categories (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  name        text        not null check (char_length(name) <= 20),
  type        text        not null check (type in ('income', 'expense')),
  icon        text        not null default 'category',
  color_hex   text        not null default '#607D8B' check (char_length(color_hex) = 7),
  is_default  boolean     not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ─── fixed_expenses ──────────────────────────────────────────
create table public.fixed_expenses (
  id            uuid        primary key default gen_random_uuid(),
  user_id       uuid        not null references public.users(id) on delete cascade,
  category_id   uuid        references public.categories(id) on delete set null,
  title         text        not null check (char_length(title) <= 30),
  amount        integer     not null check (amount > 0),
  cycle         text        not null default 'monthly' check (cycle in ('monthly', 'yearly')),
  billing_day   integer     not null check (billing_day between 1 and 31),
  next_due_date text,
  memo          text        check (char_length(memo) <= 100),
  is_active     boolean     not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ─── transactions ────────────────────────────────────────────
create table public.transactions (
  id               uuid        primary key default gen_random_uuid(),
  user_id          uuid        not null references public.users(id) on delete cascade,
  category_id      uuid        references public.categories(id) on delete set null,
  fixed_expense_id uuid        references public.fixed_expenses(id) on delete set null,
  type             text        not null check (type in ('income', 'expense')),
  amount           integer     not null check (amount > 0),
  title            text        not null check (char_length(title) <= 50),
  memo             text        check (char_length(memo) <= 200),
  occurred_at      timestamptz not null default now(),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- ─── budgets ─────────────────────────────────────────────────
create table public.budgets (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references public.users(id) on delete cascade,
  month       text        not null check (month ~ '^\d{4}-\d{2}$'),
  total_limit integer     not null check (total_limit >= 0),
  note        text        check (char_length(note) <= 100),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, month)
);

-- ─── budget_categories ───────────────────────────────────────
create table public.budget_categories (
  id           uuid        primary key default gen_random_uuid(),
  user_id      uuid        not null references public.users(id) on delete cascade,
  month        text        not null check (month ~ '^\d{4}-\d{2}$'),
  category_id  uuid        not null references public.categories(id) on delete cascade,
  limit_amount integer     not null default 0 check (limit_amount >= 0),
  spent_amount integer     not null default 0 check (spent_amount >= 0),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (user_id, month, category_id)
);

-- ─── notification_settings ───────────────────────────────────
create table public.notification_settings (
  id                    uuid        primary key default gen_random_uuid(),
  user_id               uuid        not null unique references public.users(id) on delete cascade,
  master_enabled        boolean     not null default true,
  daily_summary_enabled boolean     not null default false,
  daily_summary_time    text        not null default '20:00' check (char_length(daily_summary_time) = 5),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

-- ─── notification_rules ──────────────────────────────────────
create table public.notification_rules (
  id                  uuid        primary key default gen_random_uuid(),
  user_id             uuid        not null references public.users(id) on delete cascade,
  fixed_expense_id    uuid        not null references public.fixed_expenses(id) on delete cascade,
  title               text        not null,
  is_enabled          boolean     not null default true,
  remind_days_before  integer     not null default 2 check (remind_days_before between 0 and 7),
  remind_at           text        not null default '09:00' check (char_length(remind_at) = 5),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ─── Row Level Security ──────────────────────────────────────
alter table public.users                enable row level security;
alter table public.categories           enable row level security;
alter table public.fixed_expenses       enable row level security;
alter table public.transactions         enable row level security;
alter table public.budgets              enable row level security;
alter table public.budget_categories    enable row level security;
alter table public.notification_settings enable row level security;
alter table public.notification_rules   enable row level security;

-- 모든 테이블에 동일 패턴: 자기 데이터만 CRUD 가능
create policy "own data" on public.users           for all using (auth.uid() = id);
create policy "own data" on public.categories      for all using (auth.uid() = user_id);
create policy "own data" on public.fixed_expenses  for all using (auth.uid() = user_id);
create policy "own data" on public.transactions    for all using (auth.uid() = user_id);
create policy "own data" on public.budgets         for all using (auth.uid() = user_id);
create policy "own data" on public.budget_categories for all using (auth.uid() = user_id);
create policy "own data" on public.notification_settings for all using (auth.uid() = user_id);
create policy "own data" on public.notification_rules for all using (auth.uid() = user_id);

-- ─── 회원가입 트리거: users 프로필 자동 생성 ─────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.users (id, email, name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', '')
  );
  insert into public.notification_settings (user_id)
  values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─── 기본 카테고리 함수 (회원가입 후 호출) ───────────────────
create or replace function public.seed_default_categories(p_user_id uuid)
returns void language plpgsql security definer as $$
begin
  insert into public.categories (user_id, name, type, icon, color_hex, is_default) values
    (p_user_id, '식비',   'expense', 'restaurant',           '#FF7043', true),
    (p_user_id, '교통',   'expense', 'directions_bus',       '#42A5F5', true),
    (p_user_id, '쇼핑',   'expense', 'shopping_bag',         '#AB47BC', true),
    (p_user_id, '공과금', 'expense', 'receipt_long',         '#26A69A', true),
    (p_user_id, '의료',   'expense', 'local_hospital',       '#EF5350', true),
    (p_user_id, '문화',   'expense', 'movie',                '#FF7043', true),
    (p_user_id, '여가',   'expense', 'sports_esports',       '#66BB6A', true),
    (p_user_id, '기타',   'expense', 'more_horiz',           '#78909C', true),
    (p_user_id, '급여',   'income',  'account_balance_wallet','#29B6F6', true),
    (p_user_id, '용돈',   'income',  'card_giftcard',        '#26C6DA', true),
    (p_user_id, '부수입', 'income',  'trending_up',          '#66BB6A', true),
    (p_user_id, '기타',   'income',  'more_horiz',           '#78909C', true);
end;
$$;
```

- [ ] **Step 2: Supabase Dashboard에서 SQL 실행 (수동)**

  Supabase 프로젝트 대시보드 → SQL Editor → 위 SQL 붙여넣고 실행

---

### Task 2: pubspec.yaml 업데이트

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: supabase_flutter 추가, sqflite/path 제거**

```yaml
dependencies:
  flutter:
    sdk: flutter

  # ── Supabase ────────────────────────────────────────────────
  supabase_flutter: ^2.8.4

  # ── State Management ───────────────────────────────────────
  provider: ^6.1.2

  # ── Utils ──────────────────────────────────────────────────
  intl: ^0.19.0

  # ── Chart ──────────────────────────────────────────────────
  fl_chart: ^0.69.0

  # ── Secure Storage (자동로그인 토큰) ─────────────────────────
  flutter_secure_storage: ^9.2.4
```

- [ ] **Step 2: 패키지 설치**

```bash
cd <project-root>
flutter pub get
```

Expected: `Got dependencies!`

---

### Task 3: Supabase 설정 파일

**Files:**
- Create: `lib/core/supabase/supabase_config.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/core/supabase/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static SupabaseClient get client => Supabase.instance.client;
}
```

> ⚠️ Supabase URL과 anon key는 소스에 직접 입력하지 말고
> `--dart-define` 또는 `--dart-define-from-file=.env`로 전달

---

### Task 4: 데이터 모델 작성

**Files:**
- Modify: `lib/data/models/transaction.dart`
- Create: `lib/data/models/app_user.dart`
- Create: `lib/data/models/category.dart`
- Create: `lib/data/models/fixed_expense.dart`
- Create: `lib/data/models/budget.dart`
- Create: `lib/data/models/notification_setting.dart`
- Create: `lib/data/models/notification_rule.dart`

- [ ] **Step 1: transaction.dart 교체**

```dart
// lib/data/models/transaction.dart
enum TransactionType { income, expense }

class AppTransaction {
  final String id;
  final String userId;
  final String? categoryId;
  final String? fixedExpenseId;
  final TransactionType type;
  final int amount;
  final String title;
  final String? memo;
  final DateTime occurredAt;
  final DateTime createdAt;

  const AppTransaction({
    required this.id,
    required this.userId,
    this.categoryId,
    this.fixedExpenseId,
    required this.type,
    required this.amount,
    required this.title,
    this.memo,
    required this.occurredAt,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  factory AppTransaction.fromMap(Map<String, dynamic> map) {
    return AppTransaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String?,
      fixedExpenseId: map['fixed_expense_id'] as String?,
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: map['amount'] as int,
      title: map['title'] as String,
      memo: map['memo'] as String?,
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (fixedExpenseId != null) 'fixed_expense_id': fixedExpenseId,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'title': title,
      if (memo != null) 'memo': memo,
      'occurred_at': occurredAt.toIso8601String(),
    };
  }
}
```

- [ ] **Step 2: app_user.dart 생성**

```dart
// lib/data/models/app_user.dart
class AppUser {
  final String id;
  final String email;
  final String name;
  final int monthlyIncome;
  final String currency;
  final bool isProfileCompleted;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.monthlyIncome,
    required this.currency,
    required this.isProfileCompleted,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String? ?? '',
      monthlyIncome: map['monthly_income'] as int? ?? 0,
      currency: map['currency'] as String? ?? 'KRW',
      isProfileCompleted: map['is_profile_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'monthly_income': monthlyIncome,
      'currency': currency,
      'is_profile_completed': isProfileCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
```

- [ ] **Step 3: category.dart 생성**

```dart
// lib/data/models/category.dart
import 'package:flutter/material.dart';

class AppCategory {
  final String id;
  final String userId;
  final String name;
  final String type; // 'income' | 'expense'
  final String icon;
  final String colorHex;
  final bool isDefault;

  const AppCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorHex,
    this.isDefault = false,
  });

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String,
      colorHex: map['color_hex'] as String,
      isDefault: map['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color_hex': colorHex,
      'is_default': isDefault,
    };
  }

  static IconData getIconData(String iconName) {
    const iconMap = {
      'restaurant': Icons.restaurant,
      'directions_bus': Icons.directions_bus,
      'shopping_bag': Icons.shopping_bag,
      'receipt_long': Icons.receipt_long,
      'local_hospital': Icons.local_hospital,
      'movie': Icons.movie,
      'sports_esports': Icons.sports_esports,
      'more_horiz': Icons.more_horiz,
      'account_balance_wallet': Icons.account_balance_wallet,
      'card_giftcard': Icons.card_giftcard,
      'trending_up': Icons.trending_up,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
```

- [ ] **Step 4: fixed_expense.dart 생성**

```dart
// lib/data/models/fixed_expense.dart
class AppFixedExpense {
  final String id;
  final String userId;
  final String? categoryId;
  final String title;
  final int amount;
  final String cycle; // 'monthly' | 'yearly'
  final int billingDay;
  final String? nextDueDate;
  final String? memo;
  final bool isActive;

  const AppFixedExpense({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    required this.amount,
    required this.cycle,
    required this.billingDay,
    this.nextDueDate,
    this.memo,
    required this.isActive,
  });

  factory AppFixedExpense.fromMap(Map<String, dynamic> map) {
    return AppFixedExpense(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['category_id'] as String?,
      title: map['title'] as String,
      amount: map['amount'] as int,
      cycle: map['cycle'] as String,
      billingDay: map['billing_day'] as int,
      nextDueDate: map['next_due_date'] as String?,
      memo: map['memo'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      'title': title,
      'amount': amount,
      'cycle': cycle,
      'billing_day': billingDay,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (memo != null) 'memo': memo,
      'is_active': isActive,
    };
  }
}
```

- [ ] **Step 5: budget.dart 생성**

```dart
// lib/data/models/budget.dart
class AppBudget {
  final String id;
  final String userId;
  final String month; // 'YYYY-MM'
  final int totalLimit;
  final String? note;

  const AppBudget({
    required this.id,
    required this.userId,
    required this.month,
    required this.totalLimit,
    this.note,
  });

  factory AppBudget.fromMap(Map<String, dynamic> map) {
    return AppBudget(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      month: map['month'] as String,
      totalLimit: map['total_limit'] as int,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'user_id': userId,
      'month': month,
      'total_limit': totalLimit,
      if (note != null) 'note': note,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
```

- [ ] **Step 6: notification_setting.dart 생성**

```dart
// lib/data/models/notification_setting.dart
class AppNotificationSetting {
  final String id;
  final String userId;
  final bool masterEnabled;
  final bool dailySummaryEnabled;
  final String dailySummaryTime; // 'HH:mm'

  const AppNotificationSetting({
    required this.id,
    required this.userId,
    required this.masterEnabled,
    required this.dailySummaryEnabled,
    required this.dailySummaryTime,
  });

  factory AppNotificationSetting.fromMap(Map<String, dynamic> map) {
    return AppNotificationSetting(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      masterEnabled: map['master_enabled'] as bool? ?? true,
      dailySummaryEnabled: map['daily_summary_enabled'] as bool? ?? false,
      dailySummaryTime: map['daily_summary_time'] as String? ?? '20:00',
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'master_enabled': masterEnabled,
      'daily_summary_enabled': dailySummaryEnabled,
      'daily_summary_time': dailySummaryTime,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
```

- [ ] **Step 7: notification_rule.dart 생성**

```dart
// lib/data/models/notification_rule.dart
class AppNotificationRule {
  final String id;
  final String userId;
  final String fixedExpenseId;
  final String title;
  final bool isEnabled;
  final int remindDaysBefore;
  final String remindAt; // 'HH:mm'

  const AppNotificationRule({
    required this.id,
    required this.userId,
    required this.fixedExpenseId,
    required this.title,
    required this.isEnabled,
    required this.remindDaysBefore,
    required this.remindAt,
  });

  factory AppNotificationRule.fromMap(Map<String, dynamic> map) {
    return AppNotificationRule(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fixedExpenseId: map['fixed_expense_id'] as String,
      title: map['title'] as String,
      isEnabled: map['is_enabled'] as bool? ?? true,
      remindDaysBefore: map['remind_days_before'] as int? ?? 2,
      remindAt: map['remind_at'] as String? ?? '09:00',
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'fixed_expense_id': fixedExpenseId,
      'title': title,
      'is_enabled': isEnabled,
      'remind_days_before': remindDaysBefore,
      'remind_at': remindAt,
    };
  }
}
```

- [ ] **Step 8: 빌드 확인**

```bash
cd <project-root>
flutter analyze lib/data/models/
```

Expected: `No issues found!`

---

## Chunk 2: Repository 레이어

### Task 5: AuthRepository

**Files:**
- Create: `lib/data/repositories/auth_repository.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/data/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_config.dart';
import '../models/app_user.dart';

class AuthRepository {
  final _client = SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    if (response.user == null) {
      throw Exception('회원가입에 실패했습니다.');
    }
    // 기본 카테고리 시드
    await _client.rpc('seed_default_categories', params: {
      'p_user_id': response.user!.id,
    });
    return _fetchProfile(response.user!.id);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('이메일 또는 비밀번호가 올바르지 않습니다.');
    }
    return _fetchProfile(response.user!.id);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AppUser> fetchCurrentProfile() async {
    final user = currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');
    return _fetchProfile(user.id);
  }

  Future<void> updateProfile(AppUser user) async {
    await _client
        .from('users')
        .update(user.toUpdateMap())
        .eq('id', user.id);
  }

  Future<AppUser> _fetchProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return AppUser.fromMap(data);
  }
}
```

---

### Task 6: CategoryRepository

**Files:**
- Create: `lib/data/repositories/category_repository.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/data/repositories/category_repository.dart
import '../../core/supabase/supabase_config.dart';
import '../models/category.dart';

class CategoryRepository {
  final _client = SupabaseConfig.client;

  Future<List<AppCategory>> fetchAll({String? type}) async {
    var query = _client.from('categories').select();
    if (type != null) {
      query = query.eq('type', type) as dynamic;
    }
    final data = await query.order('name');
    return (data as List).map((e) => AppCategory.fromMap(e)).toList();
  }

  Future<AppCategory> insert(AppCategory category) async {
    final data = await _client
        .from('categories')
        .insert(category.toInsertMap())
        .select()
        .single();
    return AppCategory.fromMap(data);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    await _client
        .from('categories')
        .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
```

---

### Task 7: TransactionRepository

**Files:**
- Create: `lib/data/repositories/transaction_repository.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/data/repositories/transaction_repository.dart
import '../../core/supabase/supabase_config.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final _client = SupabaseConfig.client;

  Future<List<AppTransaction>> fetchForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1).toIso8601String();
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59).toIso8601String();

    final data = await _client
        .from('transactions')
        .select()
        .gte('occurred_at', start)
        .lte('occurred_at', end)
        .order('occurred_at', ascending: false);

    return (data as List).map((e) => AppTransaction.fromMap(e)).toList();
  }

  Future<AppTransaction> insert(AppTransaction tx) async {
    final data = await _client
        .from('transactions')
        .insert(tx.toInsertMap())
        .select()
        .single();
    return AppTransaction.fromMap(data);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    await _client
        .from('transactions')
        .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  Future<Map<String, int>> monthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1).toIso8601String();
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59).toIso8601String();

    final data = await _client
        .from('transactions')
        .select('type, amount')
        .gte('occurred_at', start)
        .lte('occurred_at', end);

    int income = 0, expense = 0;
    for (final row in (data as List)) {
      if (row['type'] == 'income') {
        income += row['amount'] as int;
      } else {
        expense += row['amount'] as int;
      }
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  Future<List<Map<String, dynamic>>> categoryExpenseSummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1).toIso8601String();
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59).toIso8601String();

    final data = await _client
        .from('transactions')
        .select('category_id, amount, categories(name, icon, color_hex)')
        .eq('type', 'expense')
        .gte('occurred_at', start)
        .lte('occurred_at', end);

    final Map<String, Map<String, dynamic>> grouped = {};
    for (final row in (data as List)) {
      final catId = row['category_id'] as String? ?? 'uncategorized';
      if (!grouped.containsKey(catId)) {
        grouped[catId] = {
          'category_id': catId,
          'name': row['categories']?['name'] ?? '기타',
          'icon': row['categories']?['icon'] ?? 'more_horiz',
          'color_hex': row['categories']?['color_hex'] ?? '#78909C',
          'total': 0,
        };
      }
      grouped[catId]!['total'] =
          (grouped[catId]!['total'] as int) + (row['amount'] as int);
    }

    final result = grouped.values.toList()
      ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
    return result;
  }
}
```

---

### Task 8: FixedExpenseRepository

**Files:**
- Create: `lib/data/repositories/fixed_expense_repository.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/data/repositories/fixed_expense_repository.dart
import '../../core/supabase/supabase_config.dart';
import '../models/fixed_expense.dart';
import '../models/notification_rule.dart';

class FixedExpenseRepository {
  final _client = SupabaseConfig.client;

  Future<List<AppFixedExpense>> fetchAll() async {
    final data = await _client
        .from('fixed_expenses')
        .select()
        .order('billing_day');
    return (data as List).map((e) => AppFixedExpense.fromMap(e)).toList();
  }

  Future<AppFixedExpense> insert(AppFixedExpense expense) async {
    final data = await _client
        .from('fixed_expenses')
        .insert(expense.toInsertMap())
        .select()
        .single();
    return AppFixedExpense.fromMap(data);
  }

  Future<void> update(String id, Map<String, dynamic> fields) async {
    await _client
        .from('fixed_expenses')
        .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('fixed_expenses').delete().eq('id', id);
  }

  // --- Notification Rules ---
  Future<List<AppNotificationRule>> fetchRules() async {
    final data = await _client.from('notification_rules').select();
    return (data as List).map((e) => AppNotificationRule.fromMap(e)).toList();
  }

  Future<AppNotificationRule> insertRule(AppNotificationRule rule) async {
    final data = await _client
        .from('notification_rules')
        .insert(rule.toInsertMap())
        .select()
        .single();
    return AppNotificationRule.fromMap(data);
  }

  Future<void> updateRule(String id, Map<String, dynamic> fields) async {
    await _client
        .from('notification_rules')
        .update({...fields, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> deleteRule(String id) async {
    await _client.from('notification_rules').delete().eq('id', id);
  }
}
```

---

### Task 9: BudgetRepository

**Files:**
- Create: `lib/data/repositories/budget_repository.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/data/repositories/budget_repository.dart
import '../../core/supabase/supabase_config.dart';
import '../models/budget.dart';

class BudgetRepository {
  final _client = SupabaseConfig.client;

  Future<AppBudget?> fetchForMonth(String userId, String month) async {
    final data = await _client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('month', month)
        .maybeSingle();
    if (data == null) return null;
    return AppBudget.fromMap(data);
  }

  Future<AppBudget> upsert(AppBudget budget) async {
    final data = await _client
        .from('budgets')
        .upsert(budget.toUpsertMap(), onConflict: 'user_id,month')
        .select()
        .single();
    return AppBudget.fromMap(data);
  }
}
```

---

### Task 10: NotificationRepository

**Files:**
- Create: `lib/data/repositories/notification_repository.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/data/repositories/notification_repository.dart
import '../../core/supabase/supabase_config.dart';
import '../models/notification_setting.dart';

class NotificationRepository {
  final _client = SupabaseConfig.client;

  Future<AppNotificationSetting?> fetchSettings(String userId) async {
    final data = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return AppNotificationSetting.fromMap(data);
  }

  Future<void> updateSettings(AppNotificationSetting settings) async {
    await _client
        .from('notification_settings')
        .update(settings.toUpdateMap())
        .eq('id', settings.id);
  }
}
```

---

## Chunk 3: Provider 레이어 + 화면 연동

### Task 11: AuthProvider 생성

**Files:**
- Create: `lib/providers/auth_provider.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();

  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _repo.isLoggedIn;

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _repo.signIn(email: email, password: password);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _repo.signUp(email: email, password: password, name: name);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    try {
      _user = await _repo.fetchCurrentProfile();
      notifyListeners();
    } catch (_) {}
  }
}
```

---

### Task 12: TransactionProvider 교체

**Files:**
- Modify: `lib/providers/transaction_provider.dart`

- [ ] **Step 1: 파일 전면 교체**

```dart
// lib/providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';
import '../core/supabase/supabase_config.dart';

class CategorySummary {
  final String categoryId;
  final String name;
  final String icon;
  final String colorHex;
  final int amount;

  const CategorySummary({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.amount,
  });
}

class MonthlyTrend {
  final DateTime month;
  final int income;
  final int expense;

  const MonthlyTrend({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class TransactionProvider extends ChangeNotifier {
  final _repo = TransactionRepository();

  List<AppTransaction> _transactions = [];
  Map<String, int> _summary = {'income': 0, 'expense': 0, 'balance': 0};
  List<CategorySummary> _categoryExpenses = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;
  String? _error;

  List<AppTransaction> get transactions => List.unmodifiable(_transactions);
  Map<String, int> get summary => Map.unmodifiable(_summary);
  List<CategorySummary> get categoryExpenses => List.unmodifiable(_categoryExpenses);
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalIncome => _summary['income'] ?? 0;
  int get totalExpense => _summary['expense'] ?? 0;
  int get balance => _summary['balance'] ?? 0;

  List<AppTransaction> recentTransactions({int limit = 5}) {
    return _transactions.take(limit).toList();
  }

  Future<void> loadForMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.fetchForMonth(_selectedMonth),
        _repo.monthlySummary(_selectedMonth),
        _repo.categoryExpenseSummary(_selectedMonth),
      ]);

      _transactions = results[0] as List<AppTransaction>;
      _summary = results[1] as Map<String, int>;

      final rawCategories = results[2] as List<Map<String, dynamic>>;
      _categoryExpenses = rawCategories
          .map((e) => CategorySummary(
                categoryId: e['category_id'] as String,
                name: e['name'] as String,
                icon: e['icon'] as String,
                colorHex: e['color_hex'] as String,
                amount: e['total'] as int,
              ))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('TransactionProvider.loadForMonth error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(AppTransaction tx) async {
    try {
      await _repo.insert(tx);
      await loadForMonth(_selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repo.delete(id);
      await loadForMonth(_selectedMonth);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<MonthlyTrend>> fetchMonthlyTrends({int count = 5}) async {
    final now = DateTime.now();
    final futures = List.generate(count, (i) {
      final m = DateTime(now.year, now.month - (count - 1 - i));
      return _repo.monthlySummary(m).then((s) => MonthlyTrend(
            month: m,
            income: s['income'] ?? 0,
            expense: s['expense'] ?? 0,
          ));
    });
    return Future.wait(futures);
  }

  String get currentUserId =>
      SupabaseConfig.client.auth.currentUser?.id ?? '';
}
```

---

### Task 13: CategoryProvider 생성

**Files:**
- Create: `lib/providers/category_provider.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/providers/category_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final _repo = CategoryRepository();

  List<AppCategory> _categories = [];
  bool _isLoading = false;

  List<AppCategory> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;

  List<AppCategory> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();

  List<AppCategory> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();

  AppCategory? findById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } on StateError {
      return null;
    }
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _repo.fetchAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(AppCategory category) async {
    await _repo.insert(category);
    await load();
  }

  Future<void> deleteCategory(String id) async {
    await _repo.delete(id);
    await load();
  }
}
```

---

### Task 14: FixedExpenseProvider 생성

**Files:**
- Create: `lib/providers/fixed_expense_provider.dart`

- [ ] **Step 1: 파일 생성**

```dart
// lib/providers/fixed_expense_provider.dart
import 'package:flutter/foundation.dart';
import '../data/models/fixed_expense.dart';
import '../data/models/notification_rule.dart';
import '../data/repositories/fixed_expense_repository.dart';

class FixedExpenseProvider extends ChangeNotifier {
  final _repo = FixedExpenseRepository();

  List<AppFixedExpense> _expenses = [];
  List<AppNotificationRule> _rules = [];
  bool _isLoading = false;

  List<AppFixedExpense> get expenses => List.unmodifiable(_expenses);
  List<AppNotificationRule> get rules => List.unmodifiable(_rules);
  bool get isLoading => _isLoading;

  int get totalMonthlyFixed =>
      _expenses.where((e) => e.isActive).fold(0, (sum, e) => sum + e.amount);

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchAll(),
        _repo.fetchRules(),
      ]);
      _expenses = results[0] as List<AppFixedExpense>;
      _rules = results[1] as List<AppNotificationRule>;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(AppFixedExpense expense) async {
    final inserted = await _repo.insert(expense);
    // 알림 규칙 자동 생성
    await _repo.insertRule(AppNotificationRule(
      id: '',
      userId: expense.userId,
      fixedExpenseId: inserted.id,
      title: expense.title,
      isEnabled: true,
      remindDaysBefore: 2,
      remindAt: '09:00',
    ));
    await load();
  }

  Future<void> toggleRule(String ruleId, bool enabled) async {
    await _repo.updateRule(ruleId, {'is_enabled': enabled});
    await load();
  }

  Future<void> deleteExpense(String id) async {
    await _repo.delete(id);
    await load();
  }
}
```

---

### Task 15: main.dart 업데이트

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Supabase 초기화 + Provider 등록 + 인증 흐름 반영**

```dart
// lib/main.dart (교체)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/category_provider.dart';
import 'providers/fixed_expense_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/intro/intro_screen.dart';
import 'screens/report/report_screen.dart';
import 'screens/notification/notification_screen.dart';
import 'screens/mypage/mypage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => FixedExpenseProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: '통합 지출관리',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _RootGate(),
      ),
    );
  }
}

/// Supabase 세션 상태에 따라 화면 분기
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _showIntro = true;
  bool _showSignup = false;

  @override
  Widget build(BuildContext context) {
    final session = SupabaseConfig.client.auth.currentSession;

    if (_showIntro) {
      return IntroScreen(onStart: () => setState(() => _showIntro = false));
    }

    if (session == null) {
      if (_showSignup) {
        return SignupScreen(
          onComplete: () => setState(() => _showSignup = false),
          onBackToLogin: () => setState(() => _showSignup = false),
        );
      }
      return LoginScreen(
        onLogin: () => setState(() {}),
        onSignup: () => setState(() => _showSignup = true),
      );
    }

    return const MainNavigationScreen();
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
    // 로그인 직후 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<TransactionProvider>().loadForMonth(now);
      context.read<CategoryProvider>().load();
      context.read<FixedExpenseProvider>().load();
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
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: '홈'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: '내역'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: '리포트'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: '알림'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: '마이'),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
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
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
```

---

### Task 16: 인증 화면 Supabase 연동

**Files:**
- Modify: `lib/screens/auth/login_screen.dart`
- Modify: `lib/screens/auth/signup_screen.dart`

- [ ] **Step 1: login_screen.dart — AuthProvider 사용하도록 수정**

기존 `onLogin` 콜백 호출 전에 `AuthProvider.signIn()` 호출 추가:

```dart
// login_screen.dart 내 _onLoginPressed() 메서드 교체
Future<void> _onLoginPressed(BuildContext context) async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  if (email.isEmpty || password.isEmpty) return;

  final auth = context.read<AuthProvider>();
  final ok = await auth.signIn(email, password);
  if (ok && context.mounted) {
    widget.onLogin();
  } else if (context.mounted && auth.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.error!)),
    );
  }
}
```

- [ ] **Step 2: signup_screen.dart — AuthProvider 사용하도록 수정**

```dart
// signup_screen.dart 내 _onSignupPressed() 메서드 교체
Future<void> _onSignupPressed(BuildContext context) async {
  final name = _nameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  if (name.isEmpty || email.isEmpty || password.isEmpty) return;

  final auth = context.read<AuthProvider>();
  final ok = await auth.signUp(email, password, name);
  if (ok && context.mounted) {
    widget.onComplete();
  } else if (context.mounted && auth.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.error!)),
    );
  }
}
```

---

### Task 17: home_screen.dart 현재 월 동적 처리

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

- [ ] **Step 1: 하드코딩된 `DateTime(2025, 5)` → 동적 처리**

```dart
// home_screen.dart build() 상단 변경
final provider = context.watch<TransactionProvider>();
final month = provider.selectedMonth;          // ← 변경
final income = provider.totalIncome;           // ← 변경
final expense = provider.totalExpense;         // ← 변경
final balance = provider.balance;              // ← 변경
final recent = provider.recentTransactions(limit: 5);
```

`_TransactionEntrySheet`의 저장 버튼에서 `AppTransaction` 생성:

```dart
// _TransactionEntrySheetState._onSave()
final userId = context.read<TransactionProvider>().currentUserId;
final tx = AppTransaction(
  id: '',
  userId: userId,
  categoryId: _selectedCategoryId,
  type: widget.type == TransactionType.income
      ? AppTransactionType.income
      : AppTransactionType.expense,
  amount: amount,
  title: _titleController.text.trim(),
  occurredAt: DateTime.now(),
  createdAt: DateTime.now(),
);
await context.read<TransactionProvider>().addTransaction(tx);
```

> `TransactionType`을 `AppTransaction`의 enum과 맞게 조정 필요

---

### Task 18: 최종 빌드 확인

- [ ] **Step 1: 분석**

```bash
cd <project-root>
flutter analyze
```

Expected: `No issues found!` (또는 info 수준만)

- [ ] **Step 2: 실행 확인**

```bash
flutter run
```

Expected: 앱 실행 → 인트로 → 로그인 화면 → Supabase 로그인 성공 → 메인 화면 데이터 표시

- [ ] **Step 3: 커밋**

```bash
cd <project-root>
git add -A
git commit -m "feat: Supabase 백엔드 연동 (8개 테이블, Auth, Repository 패턴)"
```

---

## 요약: 구현 순서

1. **Supabase Dashboard**에서 SQL 실행 (Task 1 Step 2)
2. `SupabaseConfig`에 URL/anonKey 입력 (Task 3)
3. Task 2 → 3 → 4 → 5~10 → 11~14 → 15 → 16 → 17 → 18 순서로 진행

> 각 Task는 독립적으로 빌드 가능. Task 5~10(Repository)은 순서 무관하게 병렬 작업 가능.
