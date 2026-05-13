-- Performance index for monthly transaction queries
-- Supports: WHERE user_id = $1 AND occurred_at BETWEEN $2 AND $3 ORDER BY occurred_at DESC
CREATE INDEX IF NOT EXISTS idx_transactions_user_occurred
  ON public.transactions (user_id, occurred_at DESC);
