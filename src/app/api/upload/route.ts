import { NextResponse } from 'next/server';
import { uploadFile } from '@/lib/aws/upload';

export async function POST(request: Request) {
  try {
    console.log('Upload request received');
    console.log('Content-Type:', request.headers.get('content-type'));
    
    // Check if request has body
    const hasBody = request.body !== null;
    console.log('Request has body:', hasBody);
    
    if (!hasBody) {
      return NextResponse.json({ 
        error: 'Request body is empty' 
      }, { status: 400 });
    }
    
    let body;
    try {
      body = await request.json();
    } catch (jsonError) {
      console.error('JSON parsing error:', jsonError);
      return NextResponse.json({ 
        error: 'Invalid JSON in request body' 
      }, { status: 400 });
    }
    
    console.log('Request body:', { 
      bucket: body.bucket, 
      key: body.key, 
      fileType: typeof body.file,
      fileLength: body.file?.length || 'undefined'
    });
    
    const { bucket, key, file } = body;
    
    // Validate required fields
    if (!bucket || !key || !file) {
      return NextResponse.json({ 
        error: 'Missing required fields: bucket, key, or file' 
      }, { status: 400 });
    }
    
    // Check if file is a string (base64 encoded)
    if (typeof file !== 'string') {
      console.error('File is not a string, received:', typeof file, file);
      return NextResponse.json({ 
        error: 'File must be a base64 encoded string' 
      }, { status: 400 });
    }
    
    // Convert base64 string to Buffer
    let fileBuffer;
    try {
      fileBuffer = Buffer.from(file, 'base64');
      console.log('Successfully converted to buffer, size:', fileBuffer.length);
    } catch (bufferError) {
      console.error('Error converting base64 to buffer:', bufferError);
      return NextResponse.json({ 
        error: 'Invalid base64 file data' 
      }, { status: 400 });
    }
    
    // Upload to S3
    await uploadFile(bucket, key, fileBuffer);
    console.log('File uploaded successfully to S3');

    return NextResponse.json({ message: 'File uploaded successfully', key });
  } catch (error) {
    console.error('Error uploading file:', error);
    return NextResponse.json({ 
      error: 'Failed to upload file', 
      details: error instanceof Error ? error.message : 'Unknown error'
    }, { status: 500 });
  }
}
