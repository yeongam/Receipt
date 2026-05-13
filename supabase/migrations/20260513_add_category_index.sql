-- Index for filtering and sorting transactions by user, category, and date.
-- Speeds up category breakdown queries on the report screen.
CREATE INDEX IF NOT EXISTS idx_transactions_user_category_occurred
  ON public.transactions (user_id, category_id, occurred_at DESC);
