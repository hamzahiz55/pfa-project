import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({
    NODE_ENV: process.env.NODE_ENV,
    DATABASE_URL: process.env.DATABASE_URL,
    DB_HOST: process.env.DB_HOST,
    DB_PORT: process.env.DB_PORT,
    DB_USER: process.env.DB_USER,
    DB_NAME: process.env.DB_NAME,
    DB_PASSWORD: process.env.DB_PASSWORD ? '***SET***' : 'NOT_SET',
    AWS_REGION: process.env.AWS_REGION,
    NEXT_PUBLIC_ENV: process.env.NEXT_PUBLIC_ENV,
    cwd: process.cwd(),
  });
}