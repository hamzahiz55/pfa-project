import { NextRequest, NextResponse } from 'next/server';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { Pool } from 'pg';
import { validateEnv, validateFileUpload } from '@/utils/validateEnv';
import { uploadFile } from '@/lib/aws/upload';
import { migrateUsersTable } from '@/utils/dbMigrate';

// Run migration on cold start
let migrationPromise: Promise<void> | null = null;
async function ensureMigration() {
  if (!migrationPromise) {
    migrationPromise = migrateUsersTable();
  }
  await migrationPromise;
}

// Initialize environment validation
try {
  validateEnv();
} catch (error: any) {
  console.error('Environment validation failed:', error.message);
  process.exit(1);
}

// Debug environment variables
console.log('DB Environment Variables:', {
  DATABASE_URL: process.env.DATABASE_URL,
  DB_HOST: process.env.DB_HOST,
  DB_PORT: process.env.DB_PORT,
  DB_USER: process.env.DB_USER,
  DB_NAME: process.env.DB_NAME,
  NODE_ENV: process.env.NODE_ENV,
});

// Initialize PostgreSQL client
let connectionString = process.env.DATABASE_URL;

// If DATABASE_URL is set but contains 'db' as hostname and we're not in Docker, fix it for local development
const isDocker = process.env.DOCKER_ENV === 'true' || process.env.NODE_ENV === 'development';
if (connectionString && connectionString.includes('@db:') && !isDocker) {
  connectionString = connectionString.replace('@db:', '@localhost:').replace(':5432/', ':5555/');
  console.log('Fixed DATABASE_URL for local development');
} else if (!connectionString) {
  // Build connection string from individual variables
  const host = process.env.DB_HOST || 'localhost';
  const port = process.env.DB_PORT || '5555';
  const user = process.env.DB_USER || 'postgres';
  const password = process.env.DB_PASSWORD || 'postgres123';
  const database = process.env.DB_NAME || 'aws_s3_manager';
  connectionString = `postgresql://${user}:${password}@${host}:${port}/${database}`;
  console.log('Built connection string from individual variables');
}

console.log('Final connection string:', connectionString.replace(/:[^:@]+@/, ':***@')); // Hide password in logs

const pool = new Pool({
  connectionString: connectionString,
});

// Initialize S3 client
const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
  },
});

export async function POST(request: NextRequest) {
  await ensureMigration();
  try {
    const formData = await request.formData();
    const name = formData.get('name') as string;
    const email = formData.get('email') as string;
    const photo = formData.get('photo') as File;

    if (!name || !email || !photo) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    // Validate file upload
    const fileValidationError = validateFileUpload(photo);
    if (fileValidationError) {
      return NextResponse.json({ error: fileValidationError }, { status: 400 });
    }

    // Upload photo to S3 using shared logic
    const photoBuffer = Buffer.from(await photo.arrayBuffer());
    const photoKey = `profile-photos/${Date.now()}-${photo.name}`;
    
    let photoUrl = '';
    
    // Check if we have valid AWS credentials and S3 bucket
    const s3BucketName = process.env.NEXT_PUBLIC_S3_BUCKET_NAME || process.env.S3_BUCKET_NAME;
    const hasValidAWSConfig = process.env.AWS_ACCESS_KEY_ID && 
                             process.env.AWS_SECRET_ACCESS_KEY && 
                             s3BucketName &&
                             process.env.AWS_ACCESS_KEY_ID !== 'your-access-key' &&
                             s3BucketName !== 'your-bucket-name';
    
    if (hasValidAWSConfig) {
      try {
        await uploadFile(s3BucketName!, photoKey, photoBuffer);
        photoUrl = `https://${s3BucketName}.s3.${process.env.AWS_REGION}.amazonaws.com/${photoKey}`;
        console.log('Photo uploaded to S3 successfully:', photoUrl);
      } catch (uploadError) {
        console.error('Failed to upload to S3:', uploadError);
        // Fall back to local storage or placeholder
        photoUrl = '/placeholder-avatar.svg';
      }
    } else {
      console.log('AWS not configured, using placeholder image');
      // Use a placeholder image when AWS is not configured
      photoUrl = '/placeholder-avatar.svg';
    }

    // Insert user into database
    const result = await pool.query(
      'INSERT INTO users (name, email, photo_url) VALUES ($1, $2, $3) RETURNING id, name, email, photo_url as "photoUrl", created_at as "createdAt"',
      [name, email, photoUrl]
    );

    return NextResponse.json({ user: result.rows[0] }, { status: 201 });
  } catch (error: any) {
    console.error('Error creating user:', error);
    return NextResponse.json({ error: 'Failed to create user' }, { status: 500 });
  }
}

export async function GET() {
  await ensureMigration();
  try {
    const result = await pool.query(
      'SELECT id, name, email, photo_url as "photoUrl", created_at as "createdAt" FROM users ORDER BY created_at DESC'
    );
    return NextResponse.json({ users: result.rows });
  } catch (error) {
    console.error('Error fetching users:', error);
    return NextResponse.json({ error: 'Failed to fetch users' }, { status: 500 });
  }
}
