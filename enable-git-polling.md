# Enable Git Polling Alternative

If webhook setup is not possible, you can enable Git polling:

1. Go to: http://localhost:8080/job/aws-s3-manager-pipeline/configure
2. Scroll to "Build Triggers"
3. Check "Poll SCM" 
4. Schedule: `H/5 * * * *` (every 5 minutes)
5. Save

This will check GitHub every 5 minutes for changes and trigger builds automatically.

## Webhook vs Polling:
- **Webhook**: Instant trigger (requires public Jenkins URL)
- **Polling**: 5-minute delay (works with localhost)