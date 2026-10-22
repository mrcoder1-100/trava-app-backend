const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const supabaseUrl = process.env.SUPABASE_URL || 'https://tsbtaammmkxlyymgdeic.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || 'sb_publishable_3sV1vwHGaRM6z_sGhSXQcg_gkNoCpPe';

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: SUPABASE_URL and SUPABASE_KEY must be provided.');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

const DATA_DIR = path.resolve(__dirname, '../../backend/data');

const COLLECTIONS = [
  'users',
  'routes',
  'bus_services',
  'partners',
  'coupons',
  'rewards',
  'crowd_reports',
  'notifications'
];

async function seedCollection(name) {
  const filePath = path.join(DATA_DIR, `${name}.json`);
  if (!fs.existsSync(filePath)) {
    console.log(`[Skip] ${name}.json not found.`);
    return;
  }

  const raw = fs.readFileSync(filePath, 'utf-8');
  let data = [];
  try {
    data = JSON.parse(raw);
  } catch (err) {
    console.error(`[Error] Parsing ${name}.json:`, err.message);
    return;
  }

  if (!Array.isArray(data) || data.length === 0) {
    console.log(`[Info] ${name} has 0 records, skipping.`);
    return;
  }

  if (name === 'notifications') {
    data = data.map((item, idx) => ({ id: item.id || `notif_${Date.now()}_${idx + 1}`, ...item }));
  }

  if (name === 'routes') {
    data = data.map(({ isDemoRoute, ...rest }) => rest);
  }

  console.log(`[Seeding] Uploading ${data.length} records to table '${name}'...`);

  // Upsert in batches of 20
  const batchSize = 20;
  for (let i = 0; i < data.length; i += batchSize) {
    const batch = data.slice(i, i + batchSize);
    const { error } = await supabase.from(name).upsert(batch);
    if (error) {
      console.error(`[Failed] Batch ${i}-${i + batch.length} for ${name}:`, error.message);
    } else {
      console.log(`[Success] Batch ${i}-${i + batch.length} upserted for ${name}.`);
    }
  }
}

async function main() {
  console.log(`===============================================`);
  console.log(`Trava Supabase Seeding Script`);
  console.log(`Target Supabase URL: ${supabaseUrl}`);
  console.log(`===============================================`);

  for (const col of COLLECTIONS) {
    await seedCollection(col);
  }

  console.log(`\nAll collections processed!`);
}

main().catch(console.error);
