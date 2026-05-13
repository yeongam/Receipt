CREATE TABLE IF NOT EXISTS public.password_reset_attempts (
  username TEXT PRIMARY KEY,
  attempt_count INT NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.password_reset_attempts ENABLE ROW LEVEL SECURITY;
