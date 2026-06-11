-- Switch public.users from email-based to username-based identity.
-- Supabase auth still uses a fake email internally ({username}@receipt.app),
-- but the app-visible identifier is now username.

ALTER TABLE public.users RENAME COLUMN email TO username;

-- Update the signup trigger to extract username from metadata.
-- Falls back to the part before '@' in the fake email if metadata is absent.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_username text;
BEGIN
  v_username := COALESCE(
    new.raw_user_meta_data->>'username',
    split_part(new.email, '@', 1)
  );
  INSERT INTO public.users (id, username, name)
  VALUES (new.id, v_username, v_username);
  INSERT INTO public.notification_settings (user_id)
  VALUES (new.id);
  RETURN new;
END;
$$;
