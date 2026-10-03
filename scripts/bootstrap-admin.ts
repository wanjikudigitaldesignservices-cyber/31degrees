import { getServerEnv } from '../supabase/functions/shared/env.ts';

console.log("Bootstrap Admin Script");
const env = getServerEnv();
console.log(`Will bootstrap admin user for: ${env.BOOTSTRAP_ADMIN_EMAIL}`);
console.log("BLOCKED: Cannot connect to database because Docker is unavailable.");
process.exit(1);
