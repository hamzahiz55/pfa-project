import { NextResponse } from 'next/server';
import { listFiles } from '@/lib/aws/list';

export async function GET(request: Request) {
  try {
    const bucket = new URL(request.url).searchParams.get('bucket');
    
    if (!bucket) {
      return NextResponse.json(
        { error: 'Bucket parameter is required' },
        { status: 400 }
      );
    }

    const files = await listFiles(bucket);
    return NextResponse.json(files);
  } catch (error: any) {
    console.error('API Error:', error);
    
    return NextResponse.json(
      { 
        error: error.message || 'Failed to list files',
        details: process.env.NODE_ENV === 'development' ? error.stack : undefined
      },
      { status: 500 }
    );
  }
}
