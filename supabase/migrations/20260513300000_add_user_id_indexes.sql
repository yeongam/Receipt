CREATE INDEX IF NOT EXISTS idx_transactions_user_id
  ON public.transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_categories_user_id
  ON public.categories(user_id);

CREATE INDEX IF NOT EXISTS idx_fixed_expenses_user_id
  ON public.fixed_expenses(user_id);

CREATE INDEX IF NOT EXISTS idx_notification_rules_user_id
  ON public.notification_rules(user_id);

CREATE INDEX IF NOT EXISTS idx_budgets_user_id
  ON public.budgets(user_id);
