/**
 * Edge Function: reset-password-with-recovery-code
 *
 * Validates username + PBKDF2 recovery code, then resets the Supabase auth
 * password using the service role key (never exposed to the client).
 *
 * Request body (JSON):
 *   { username: string, recoveryCode: string, newPassword: string }
 *
 * Responses:
 *   200 { success: true }
 *   400 { error: "invalid_credentials" | "invalid_input" }
 *   500 { error: "internal_error" }
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const PBKDF2_ITERATIONS = 50_000;
const PBKDF2_KEY_LENGTH = 32; // bytes

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
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

  // 1. Look up the user record by username.
  const { data: userRow, error: fetchErr } = await admin
    .from('users')
    .select('id, app_lock_recovery_code')
    .eq('username', username)
    .maybeSingle();

  if (fetchErr || !userRow || !userRow.app_lock_recovery_code) {
    return json({ error: 'invalid_credentials' }, 400);
  }

  // 2. Validate recovery code.
  const stored: string = userRow.app_lock_recovery_code;
  const valid = await validateRecoveryCode(recoveryCode, stored);
  if (!valid) {
    return json({ error: 'invalid_credentials' }, 400);
  }

  // 3. Reset Supabase auth password via admin API.
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

/**
 * Validates a recovery code against either:
 *   pbkdf2rc:<base64-salt>:<base64-hash>  (current format, 50 000 iterations)
 *   sha256:<hex-hash>                      (legacy format)
 */
async function validateRecoveryCode(
  input: string,
  stored: string,
): Promise<boolean> {
  if (stored.startsWith('pbkdf2rc:')) {
    const parts = stored.split(':');
    if (parts.length !== 3) return false;
    const salt = base64Decode(parts[1]);
    const expectedHash = base64Decode(parts[2]);

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

function base64Decode(b64: string): Uint8Array {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Constant-time comparison to prevent timing attacks. */
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
      'Access-Control-Allow-Origin': '*',
    },
  });
}
