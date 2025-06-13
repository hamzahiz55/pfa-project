import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '5432'}/${process.env.DB_NAME}`,
});

const createTableSQL = `
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    photo_url VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
`;

export async function migrateUsersTable() {
  try {
    await pool.query(createTableSQL);
    console.log('✅ users table is ready');
  } catch (err) {
    console.error('❌ Failed to create users table:', err);
    throw err;
  }
  // Don't close the pool in production - it's shared across the app
}

// Run automatically if called directly
if (require.main === module) {
  migrateUsersTable();
}
