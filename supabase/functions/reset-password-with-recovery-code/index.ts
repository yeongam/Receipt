import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const PBKDF2_ITERATIONS = 50_000;
const PBKDF2_KEY_LENGTH = 32;
const MAX_ATTEMPTS = 5;
const LOCKOUT_MINUTES = 30;

const ALLOWED_ORIGIN = SUPABASE_URL;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  if (req.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405);
  }

  let body: { username?: string; recoveryCode?: string; newPassword?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: 'invalid_input' }, 400);
  }

  const { username, recoveryCode, newPassword } = body;
  if (!username || !recoveryCode || !newPassword) {
    return json({ error: 'invalid_input' }, 400);
  }
  if (newPassword.length < 6) {
    return json({ error: 'password_too_short' }, 400);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // 1. Check server-side rate limit.
  const { data: attemptRow } = await admin
    .from('password_reset_attempts')
    .select('attempt_count, locked_until')
    .eq('username', username)
    .maybeSingle();

  if (attemptRow?.locked_until && new Date(attemptRow.locked_until) > new Date()) {
    return json({ error: 'too_many_attempts' }, 429);
  }

  // 2. Look up the user record by username.
  const { data: userRow, error: fetchErr } = await admin
    .from('users')
    .select('id, app_lock_recovery_code')
    .eq('username', username)
    .maybeSingle();

  if (fetchErr || !userRow || !userRow.app_lock_recovery_code) {
    await recordFailedAttempt(admin, username, attemptRow);
    return json({ error: 'invalid_credentials' }, 400);
  }

  // 3. Validate recovery code.
  const stored: string = userRow.app_lock_recovery_code;
  const valid = await validateRecoveryCode(recoveryCode, stored);
  if (!valid) {
    await recordFailedAttempt(admin, username, attemptRow);
    return json({ error: 'invalid_credentials' }, 400);
  }

  // 4. Clear rate limit on success.
  await admin
    .from('password_reset_attempts')
    .delete()
    .eq('username', username);

  // 5. Reset Supabase auth password via admin API.
  const { error: resetErr } = await admin.auth.admin.updateUserById(
    userRow.id,
    { password: newPassword },
  );

  if (resetErr) {
    console.error('[reset-password] auth update failed:', resetErr.message);
    return json({ error: 'internal_error' }, 500);
  }

  return json({ success: true }, 200);
});

async function recordFailedAttempt(
  admin: ReturnType<typeof createClient>,
  username: string,
  existing: { attempt_count: number; locked_until: string | null } | null,
) {
  const count = (existing?.attempt_count ?? 0) + 1;
  const lockedUntil = count >= MAX_ATTEMPTS
    ? new Date(Date.now() + LOCKOUT_MINUTES * 60 * 1000).toISOString()
    : null;

  await admin.from('password_reset_attempts').upsert(
    {
      username,
      attempt_count: count,
      locked_until: lockedUntil,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'username' },
  );
}

/**
 * Validates a recovery code against either:
 *   pbkdf2rc:<hex-salt>:<hex-hash>  (current format, 50 000 iterations)
 *   sha256:<hex-hash>               (legacy format)
 */
async function validateRecoveryCode(
  input: string,
  stored: string,
): Promise<boolean> {
  if (stored.startsWith('pbkdf2rc:')) {
    const parts = stored.split(':');
    if (parts.length !== 3) return false;
    const salt = hexDecode(parts[1]);
    const expectedHash = hexDecode(parts[2]);

    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(input),
      { name: 'PBKDF2' },
      false,
      ['deriveBits'],
    );
    const derived = await crypto.subtle.deriveBits(
      {
        name: 'PBKDF2',
        hash: 'SHA-256',
        salt,
        iterations: PBKDF2_ITERATIONS,
      },
      keyMaterial,
      PBKDF2_KEY_LENGTH * 8,
    );
    return timingSafeEqual(new Uint8Array(derived), expectedHash);
  }

  if (stored.startsWith('sha256:')) {
    const expectedHex = stored.slice(7);
    const digest = await crypto.subtle.digest(
      'SHA-256',
      new TextEncoder().encode(input),
    );
    const actualHex = Array.from(new Uint8Array(digest))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
    return timingSafeEqual(
      new TextEncoder().encode(actualHex),
      new TextEncoder().encode(expectedHex),
    );
  }

  return false;
}

function hexDecode(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

function timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    },
  });
}
