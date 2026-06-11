-- RPC for password reset via recovery code (unauthenticated, security definer).
-- Returns true if username + recovery_code are valid, false otherwise.
-- The actual password update is performed by a follow-up admin action or
-- an Edge Function that calls auth.admin.updateUserById.
--
-- For now, we store a short-lived reset token in a dedicated table so the
-- client can exchange it for a password update without exposing the service key.

create table if not exists public.password_reset_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  token       text not null,
  expires_at  timestamptz not null default (now() + interval '10 minutes'),
  used        boolean not null default false
);

alter table public.password_reset_tokens enable row level security;
-- No user-facing RLS policy — access only through security definer functions.

-- Step 1: validate identity and issue a short-lived reset token.
create or replace function public.issue_password_reset_token(
  p_username    text,
  p_recovery_code text
)
returns text
language plpgsql security definer
set search_path = public
as $$
declare
  v_user_id   uuid;
  v_stored    text;
  v_token     text;
  v_salt      text;
  v_hash      text;
begin
  -- Look up user by username (bypasses RLS via security definer).
  select id, app_lock_recovery_code
  into v_user_id, v_stored
  from public.users
  where username = p_username
  limit 1;

  if v_user_id is null or v_stored is null then
    return null;
  end if;

  -- Support both pbkdf2rc: format and legacy sha256: format.
  -- Client-side PBKDF2 validation is not possible in SQL, so we delegate
  -- simple format detection here and return null for pbkdf2rc codes
  -- (Edge Function required for full PBKDF2 validation).
  if v_stored not like 'sha256:%' then
    -- pbkdf2rc: codes must be validated via Edge Function.
    -- Return a sentinel so the client knows to call the Edge Function.
    return 'NEEDS_EDGE_FUNCTION';
  end if;

  -- Legacy SHA-256 path.
  v_hash := encode(digest(p_recovery_code, 'sha256'), 'hex');
  if ('sha256:' || v_hash) <> v_stored then
    return null;
  end if;

  -- Issue reset token.
  v_token := encode(gen_random_bytes(32), 'hex');
  insert into public.password_reset_tokens (user_id, token)
  values (v_user_id, v_token);

  return v_token;
end;
$$;

-- Step 2: consume token and update password (called from client with new password hash).
-- Note: Supabase auth password update requires the service role key.
-- This function is a placeholder — wire to an Edge Function for production use.
create or replace function public.consume_reset_token(
  p_token text
)
returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  delete from public.password_reset_tokens
  where token = p_token
    and used = false
    and expires_at > now()
  returning user_id into v_user_id;

  return v_user_id;
end;
$$;
