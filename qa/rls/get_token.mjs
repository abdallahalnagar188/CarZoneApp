// Get an access token for a TEST customer so customer_rls.test.mjs can run as that user.
//
// Use a Supabase "test phone number" (Dashboard -> Authentication -> Providers -> Phone ->
// "Phone numbers for testing") so no real SMS is sent and the OTP is fixed.
//
//   node rls/get_token.mjs +201000000001            -> sends OTP (skipped for test numbers)
//   node rls/get_token.mjs +201000000001 123456     -> verifies and prints the access token
//
// Then: export CZ_TEST_JWT=<token>   (and CZ_TEST_JWT_B for a second test customer)
import { createClient } from '@supabase/supabase-js';

const URL = process.env.SUPABASE_URL || 'https://tbcmgdwzarfdgzzmmele.supabase.co';
const KEY = process.env.SUPABASE_ANON_KEY ||
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRiY21nZHd6YXJmZGd6em1tZWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4MjE2NjUsImV4cCI6MjEwNzM5NzY2NX0.OBkKC0Qudh-hN_uVeB8oappJ4YY9bZzy77QSswWCmP4';

const [phone, otp] = process.argv.slice(2);
if (!phone) {
  console.error('usage: node rls/get_token.mjs <phone> [otp]');
  process.exit(1);
}

const db = createClient(URL, KEY, { auth: { persistSession: false } });

if (!otp) {
  const { error } = await db.auth.signInWithOtp({ phone });
  if (error) throw error;
  console.error('OTP requested. Re-run with the code as the second argument.');
} else {
  const { data, error } = await db.auth.verifyOtp({ phone, token: otp, type: 'sms' });
  if (error) throw error;
  console.log(data.session.access_token);
}
