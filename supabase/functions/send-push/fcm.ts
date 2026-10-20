// FCM HTTP v1 client for Deno: signs a Google OAuth JWT with the Firebase
// service account (WebCrypto, no dependencies), caches the access token and
// sends one message per call.
//
// The service account JSON comes from the FIREBASE_SERVICE_ACCOUNT secret
// (raw JSON or base64 of it). It is never logged.

export interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

export interface SendResult {
  ok: boolean;
  /** FCM message name on success. */
  name?: string;
  status?: number;
  /** e.g. UNREGISTERED, INVALID_ARGUMENT, UNAVAILABLE. */
  errorCode?: string;
  message?: string;
}

export type FcmSend = (message: Record<string, unknown>) => Promise<SendResult>;

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

export function parseServiceAccount(raw: string | undefined): ServiceAccount | null {
  if (!raw) return null;
  try {
    const text = raw.trim().startsWith("{") ? raw : atob(raw.trim());
    const sa = JSON.parse(text);
    if (sa?.project_id && sa?.client_email && sa?.private_key) return sa as ServiceAccount;
  } catch (_) {
    // fall through
  }
  return null;
}

const b64url = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

const b64urlJson = (v: unknown) => b64url(new TextEncoder().encode(JSON.stringify(v)));

function pemToDer(pem: string): ArrayBuffer {
  const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\s+/g, "");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0)).buffer;
}

export async function signJwt(sa: ServiceAccount, nowSec: number): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const unsigned = `${b64urlJson({ alg: "RS256", typ: "JWT" })}.${b64urlJson({
    iss: sa.client_email,
    scope: SCOPE,
    aud: TOKEN_URL,
    iat: nowSec,
    exp: nowSec + 3600,
  })}`;
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  return `${unsigned}.${b64url(new Uint8Array(sig))}`;
}

/** FCM puts the useful code (UNREGISTERED, …) in error.details[].errorCode. */
export function fcmErrorCode(body: unknown): string {
  const err = (body as { error?: { status?: string; details?: { errorCode?: string }[] } })?.error;
  return err?.details?.find((d) => d?.errorCode)?.errorCode ?? err?.status ?? "UNKNOWN";
}

export function createFcmSender(
  sa: ServiceAccount,
  fetchImpl: typeof fetch = fetch,
  now: () => number = Date.now,
): FcmSend {
  let cached: { token: string; expiresAt: number } | null = null;

  async function accessToken(): Promise<string> {
    if (cached && cached.expiresAt - 60_000 > now()) return cached.token;
    const res = await fetchImpl(TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: await signJwt(sa, Math.floor(now() / 1000)),
      }),
    });
    const json = await res.json().catch(() => ({}));
    if (!res.ok || !json.access_token) {
      throw new Error(`Google OAuth token request failed (${res.status}): ${json.error ?? "no token"}`);
    }
    cached = { token: json.access_token, expiresAt: now() + (json.expires_in ?? 3600) * 1000 };
    return cached.token;
  }

  const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  return async (message) => {
    const res = await fetchImpl(url, {
      method: "POST",
      headers: { Authorization: `Bearer ${await accessToken()}`, "Content-Type": "application/json" },
      body: JSON.stringify({ message }),
    });
    const json = await res.json().catch(() => ({}));
    if (res.ok) return { ok: true, name: json.name ?? "" };
    if (res.status === 401) cached = null;
    return { ok: false, status: res.status, errorCode: fcmErrorCode(json), message: json?.error?.message ?? "" };
  };
}
