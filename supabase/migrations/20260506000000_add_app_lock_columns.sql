-- Add app lock columns to public.users
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS app_lock_passcode_hash TEXT,
  ADD COLUMN IF NOT EXISTS app_lock_recovery_code TEXT;

-- Note: Existing RLS policy on public.users ("own data") already restricts access by auth.uid() = id,
-- so these app_lock columns are automatically protected at the row level.
-- Users can only read/write their own app lock data through the existing RLS policy.
