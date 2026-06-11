alter table public.users
  add column if not exists language text not null default '한국어',
  add column if not exists theme_label text not null default '라이트',
  add column if not exists start_screen text not null default '홈',
  add column if not exists compact_view boolean not null default false,
  add column if not exists show_weekly_summary boolean not null default true,
  add column if not exists lock_on_launch boolean not null default false,
  add column if not exists biometric_enabled boolean not null default false,
  add column if not exists budget_warning_primary integer not null default 80,
  add column if not exists budget_warning_secondary integer not null default 100,
  add column if not exists budget_start_day text not null default '매월 1일';

alter table public.notification_settings
  add column if not exists budget_alert_enabled boolean not null default true,
  add column if not exists fixed_expense_alert_enabled boolean not null default true;
