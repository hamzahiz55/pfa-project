import { ListObjectsCommand } from '@aws-sdk/client-s3';
import { s3Client } from './client';

/**
 * Lists files from the given S3 bucket.
 * @param bucketName The name of the S3 bucket.
 * @returns A list of files with their keys and sizes.
 */
export async function listFiles(bucketName: string): Promise<{ Key: string; Size: number }[]> {
  try {
    const command = new ListObjectsCommand({ Bucket: bucketName });
    const response = await s3Client.send(command);

    return (
      response.Contents?.map((file) => ({
        Key: file.Key || '',
        Size: file.Size || 0,
      })) || []
    );
  } catch (error: any) {
    console.error('Error listing files from S3:', error);
    
    // Provide more specific error messages
    if (error.name === 'NoSuchBucket') {
      throw new Error(`Bucket "${bucketName}" does not exist`);
    } else if (error.name === 'AccessDenied') {
      throw new Error(`Access denied to bucket "${bucketName}"`);
    } else if (error.name === 'InvalidBucketName') {
      throw new Error(`Invalid bucket name: "${bucketName}"`);
    } else if (error.$metadata?.httpStatusCode === 403) {
      throw new Error('AWS credentials may be invalid or missing required permissions');
    } else if (error.message?.includes('Credential')) {
      throw new Error('AWS credentials are not properly configured');
    }
    
    throw new Error(`Failed to list files from S3: ${error.message || 'Unknown error'}`);
  }
}
