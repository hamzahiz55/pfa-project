import { NextResponse } from 'next/server';
import { Pool } from 'pg';

export async function GET() {
  const health = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NEXT_PUBLIC_ENV || 'unknown',
    checks: {
      database: 'unknown',
      aws: 'unknown',
    },
  };

  // Check database connection
  try {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL || `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '5432'}/${process.env.DB_NAME}`,
      connectionTimeoutMillis: 5000,
    });

    const result = await pool.query('SELECT NOW()');
    await pool.end();
    
    health.checks.database = 'healthy';
  } catch (error) {
    health.checks.database = 'unhealthy';
    health.status = 'degraded';
  }

  // Check AWS credentials
  try {
    if (
      process.env.AWS_ACCESS_KEY_ID &&
      process.env.AWS_SECRET_ACCESS_KEY &&
      process.env.AWS_REGION
    ) {
      health.checks.aws = 'configured';
    } else {
      health.checks.aws = 'not configured';
      health.status = 'degraded';
    }
  } catch (error) {
    health.checks.aws = 'error';
    health.status = 'degraded';
  }

  const statusCode = health.status === 'ok' ? 200 : 503;
  
  return NextResponse.json(health, { status: statusCode });
}