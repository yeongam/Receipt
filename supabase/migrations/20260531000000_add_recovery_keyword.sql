-- Add recovery_keyword to users table for "Find ID" account recovery.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS recovery_keyword text NOT NULL DEFAULT '';

-- Update the on_auth_user_created trigger to also set recovery_keyword from metadata.
-- Re-create the trigger function to include the new column.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username text;
BEGIN
  v_username := COALESCE(
    new.raw_user_meta_data->>'username',
    split_part(new.email, '@', 1)
  );
  INSERT INTO public.users (id, username, name, recovery_keyword)
  VALUES (
    new.id,
    v_username,
    COALESCE(new.raw_user_meta_data->>'name', v_username),
    COALESCE(new.raw_user_meta_data->>'recovery_keyword', '')
  )
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        recovery_keyword = EXCLUDED.recovery_keyword;
  INSERT INTO public.notification_settings (user_id)
  VALUES (new.id)
  ON CONFLICT DO NOTHING;
  RETURN new;
END;
$$;

-- RPC: find username by name + recovery_keyword (security definer, bypasses RLS).
CREATE OR REPLACE FUNCTION public.find_username_by_recovery(
  p_name             text,
  p_recovery_keyword text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username text;
BEGIN
  SELECT username INTO v_username
  FROM public.users
  WHERE LOWER(TRIM(name)) = LOWER(TRIM(p_name))
    AND LOWER(TRIM(recovery_keyword)) = LOWER(TRIM(p_recovery_keyword))
  LIMIT 1;

  RETURN v_username;  -- NULL if not found
END;
$$;
