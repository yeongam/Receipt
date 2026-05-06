-- ============================================================
-- 통합 지출관리 Initial Schema
-- 2026-04-29
-- ============================================================

-- ─── users (auth.users 확장 프로필) ──────────────────────────
create table public.users (
  id                   uuid        primary key references auth.users(id) on delete cascade,
  email                text        not null unique,
  name                 text        not null default '',
  monthly_income       integer     not null default 0,
  currency             text        not null default 'KRW',
  is_profile_completed boolean     not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
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
alter table public.users                 enable row level security;
alter table public.categories            enable row level security;
alter table public.fixed_expenses        enable row level security;
alter table public.transactions          enable row level security;
alter table public.budgets               enable row level security;
alter table public.budget_categories     enable row level security;
alter table public.notification_settings enable row level security;
alter table public.notification_rules    enable row level security;

create policy "own data" on public.users                 for all using (auth.uid() = id);
create policy "own data" on public.categories            for all using (auth.uid() = user_id);
create policy "own data" on public.fixed_expenses        for all using (auth.uid() = user_id);
create policy "own data" on public.transactions          for all using (auth.uid() = user_id);
create policy "own data" on public.budgets               for all using (auth.uid() = user_id);
create policy "own data" on public.budget_categories     for all using (auth.uid() = user_id);
create policy "own data" on public.notification_settings for all using (auth.uid() = user_id);
create policy "own data" on public.notification_rules    for all using (auth.uid() = user_id);

-- ─── updated_at 자동 갱신 ───────────────────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_users_updated_at
  before update on public.users
  for each row execute function public.set_updated_at();

create trigger set_categories_updated_at
  before update on public.categories
  for each row execute function public.set_updated_at();

create trigger set_fixed_expenses_updated_at
  before update on public.fixed_expenses
  for each row execute function public.set_updated_at();

create trigger set_transactions_updated_at
  before update on public.transactions
  for each row execute function public.set_updated_at();

create trigger set_budgets_updated_at
  before update on public.budgets
  for each row execute function public.set_updated_at();

create trigger set_budget_categories_updated_at
  before update on public.budget_categories
  for each row execute function public.set_updated_at();

create trigger set_notification_settings_updated_at
  before update on public.notification_settings
  for each row execute function public.set_updated_at();

create trigger set_notification_rules_updated_at
  before update on public.notification_rules
  for each row execute function public.set_updated_at();

-- ─── 테넌트 소유 참조 무결성 ─────────────────────────────────
create or replace function public.ensure_fixed_expense_owned_refs()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if new.category_id is not null and not exists (
    select 1
    from public.categories category
    where category.id = new.category_id
      and category.user_id = new.user_id
  ) then
    raise exception 'fixed_expenses.category_id must belong to the same user'
      using errcode = '23503';
  end if;

  return new;
end;
$$;

create trigger ensure_fixed_expense_owned_refs
  before insert or update on public.fixed_expenses
  for each row execute function public.ensure_fixed_expense_owned_refs();

create or replace function public.ensure_transaction_owned_refs()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if new.category_id is not null and not exists (
    select 1
    from public.categories category
    where category.id = new.category_id
      and category.user_id = new.user_id
  ) then
    raise exception 'transactions.category_id must belong to the same user'
      using errcode = '23503';
  end if;

  if new.fixed_expense_id is not null and not exists (
    select 1
    from public.fixed_expenses fixed_expense
    where fixed_expense.id = new.fixed_expense_id
      and fixed_expense.user_id = new.user_id
  ) then
    raise exception 'transactions.fixed_expense_id must belong to the same user'
      using errcode = '23503';
  end if;

  return new;
end;
$$;

create trigger ensure_transaction_owned_refs
  before insert or update on public.transactions
  for each row execute function public.ensure_transaction_owned_refs();

create or replace function public.ensure_budget_category_owned_refs()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.categories category
    where category.id = new.category_id
      and category.user_id = new.user_id
  ) then
    raise exception 'budget_categories.category_id must belong to the same user'
      using errcode = '23503';
  end if;

  return new;
end;
$$;

create trigger ensure_budget_category_owned_refs
  before insert or update on public.budget_categories
  for each row execute function public.ensure_budget_category_owned_refs();

create or replace function public.ensure_notification_rule_owned_refs()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.fixed_expenses fixed_expense
    where fixed_expense.id = new.fixed_expense_id
      and fixed_expense.user_id = new.user_id
  ) then
    raise exception 'notification_rules.fixed_expense_id must belong to the same user'
      using errcode = '23503';
  end if;

  return new;
end;
$$;

create trigger ensure_notification_rule_owned_refs
  before insert or update on public.notification_rules
  for each row execute function public.ensure_notification_rule_owned_refs();

-- ─── 회원가입 트리거: users 프로필 + notification_settings 자동 생성 ──
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
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

-- ─── 기본 카테고리 시드 함수 (회원가입 후 호출) ───────────────
create or replace function public.seed_default_categories(p_user_id uuid)
returns void language plpgsql security definer
set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'seed_default_categories can only be called for the current user'
      using errcode = '42501';
  end if;

  insert into public.categories (user_id, name, type, icon, color_hex, is_default)
  select p_user_id, default_category.name, default_category.type, default_category.icon, default_category.color_hex, true
  from (values
    ('식비',   'expense', 'restaurant',             '#FF7043'),
    ('교통',   'expense', 'directions_bus',         '#42A5F5'),
    ('쇼핑',   'expense', 'shopping_bag',           '#AB47BC'),
    ('공과금', 'expense', 'receipt_long',           '#26A69A'),
    ('의료',   'expense', 'local_hospital',         '#EF5350'),
    ('문화',   'expense', 'movie',                  '#FF7043'),
    ('여가',   'expense', 'sports_esports',         '#66BB6A'),
    ('기타',   'expense', 'more_horiz',             '#78909C'),
    ('급여',   'income',  'account_balance_wallet', '#29B6F6'),
    ('용돈',   'income',  'card_giftcard',          '#26C6DA'),
    ('부수입', 'income',  'trending_up',            '#66BB6A'),
    ('기타',   'income',  'more_horiz',             '#78909C')
  ) as default_category(name, type, icon, color_hex)
  where not exists (
    select 1
    from public.categories existing
    where existing.user_id = p_user_id
      and existing.type = default_category.type
      and existing.name = default_category.name
  );
end;
$$;

revoke execute on function public.seed_default_categories(uuid) from public;
grant execute on function public.seed_default_categories(uuid) to authenticated;
