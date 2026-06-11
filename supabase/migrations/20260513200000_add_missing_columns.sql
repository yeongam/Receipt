ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS language              text    NOT NULL DEFAULT '한국어',
  ADD COLUMN IF NOT EXISTS theme_label           text    NOT NULL DEFAULT '라이트',
  ADD COLUMN IF NOT EXISTS start_screen          text    NOT NULL DEFAULT '홈',
  ADD COLUMN IF NOT EXISTS compact_view          boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS show_weekly_summary   boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS lock_on_launch        boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS biometric_enabled     boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS budget_warning_primary   integer NOT NULL DEFAULT 80,
  ADD COLUMN IF NOT EXISTS budget_warning_secondary integer NOT NULL DEFAULT 100,
  ADD COLUMN IF NOT EXISTS budget_start_day      text    NOT NULL DEFAULT '매월 1일';

ALTER TABLE public.notification_settings
  ADD COLUMN IF NOT EXISTS budget_alert_enabled        boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS fixed_expense_alert_enabled boolean NOT NULL DEFAULT true;
