import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('CRITICAL: Supabase credentials missing. The application will not function correctly.');
}

// Use a safer initialization pattern
export const supabase = createClient(
  supabaseUrl || 'https://placeholder-missing-url.supabase.co',
  supabaseAnonKey || 'placeholder-missing-key',
  {
    auth: {
      storageKey: `sb-${new URL(supabaseUrl || 'https://prive.supabase.co').hostname.split('.')[0]}-auth-token`,
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
      flowType: 'implicit' // Avoid PKCE lock complexities in dev iframes
    }
  }
);
