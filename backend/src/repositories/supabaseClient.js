const { createClient } = require('@supabase/supabase-js');
const config = require('../config');

let supabase = null;

if (config.supabaseUrl && config.supabaseKey) {
  try {
    supabase = createClient(config.supabaseUrl, config.supabaseKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false
      }
    });
    console.log('[Supabase] Initialized client for:', config.supabaseUrl);
  } catch (err) {
    console.error('[Supabase] Initialization failed:', err.message);
  }
} else {
  console.warn('[Supabase] Missing SUPABASE_URL or SUPABASE_KEY. Fallback to local JSON repository.');
}

module.exports = supabase;
