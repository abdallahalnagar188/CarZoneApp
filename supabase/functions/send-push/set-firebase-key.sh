#!/usr/bin/env bash
# Stores the Firebase service account JSON in Vault (firebase_service_account),
# which send-push needs to talk to FCM. Without it every push fails with
# "FCM is not configured".
#
#   supabase/functions/send-push/set-firebase-key.sh ~/Downloads/chatapp-188-firebase-adminsdk-xxxx.json
#
# The key is sent base64-encoded (parseServiceAccount accepts it) through a
# temporary SQL file that is deleted afterwards; it is never printed.
set -euo pipefail

key_file="${1:?usage: $0 <firebase-service-account.json>}"
grep -q '"private_key"' "$key_file" || { echo "Not a Firebase service account JSON: $key_file" >&2; exit 1; }

b64="$(base64 < "$key_file" | tr -d '\n')"
sql="$(mktemp)"
trap 'rm -f "$sql"' EXIT
cat > "$sql" <<SQL
DO \$\$
DECLARE v_id uuid;
BEGIN
  SELECT id INTO v_id FROM vault.secrets WHERE name = 'firebase_service_account';
  IF v_id IS NULL THEN
    PERFORM vault.create_secret('$b64', 'firebase_service_account');
  ELSE
    PERFORM vault.update_secret(v_id, '$b64');
  END IF;
END \$\$;
SQL

supabase db query --linked -f "$sql" > /dev/null
echo "firebase_service_account saved. New Edge Function workers pick it up on their next request."
