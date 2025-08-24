# CI/CD Dashboard Integration Guide

## Overview
This guide explains how to integrate your CI/CD tools (GitHub Actions and Jenkins) with the CI/CD Health Dashboard.

## 1. GitHub Actions Integration

### Step 1: Configure Repository Secrets
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add a new repository secret:
   - **Name**: `DASHBOARD_URL`
   - **Value**: Your dashboard URL (e.g., `https://your-dashboard.com` or `http://localhost:4000` for local testing)

### Step 2: The Workflow File
The `.github/workflows/ci.yml` file is already configured to:
- Run on push to main/develop branches
- Run on pull requests to main
- Send pipeline data to your dashboard via webhooks

### Step 3: Test the Integration
1. Make any change to your repository
2. Push to trigger the workflow
3. Check your dashboard for real pipeline data

## 2. Jenkins Integration

### Step 1: Install Required Plugins
In Jenkins, install these plugins:
- **HTTP Request Plugin**: For sending webhook data
- **Pipeline**: For running the Jenkinsfile

### Step 2: Configure Environment Variables
1. Go to **Manage Jenkins** → **Configure System**
2. Add global environment variable:
   - **Name**: `DASHBOARD_URL`
   - **Value**: Your dashboard URL

### Step 3: Create Pipeline Job
1. Create a new **Pipeline** job in Jenkins
2. Configure it to use the `Jenkinsfile` from your repository
3. Set up Git SCM to point to your repository

### Step 4: Test the Integration
1. Trigger a build in Jenkins
2. Check your dashboard for real pipeline data

## 3. Webhook Endpoints

### GitHub Actions
- **URL**: `POST {DASHBOARD_URL}/api/webhook/gha`
- **Content-Type**: `application/json`

### Jenkins
- **URL**: `POST {DASHBOARD_URL}/api/webhook/jenkins`
- **Content-Type**: `application/json`

## 4. Payload Format

Both webhooks expect the same JSON payload format:

```json
{
  "pipelineName": "string",
  "status": "success|failure|running|queued",
  "startedAt": "ISO-8601 timestamp",
  "finishedAt": "ISO-8601 timestamp (optional)",
  "durationMs": "number in milliseconds (optional)",
  "branch": "string",
  "commitSha": "string",
  "triggeredBy": "string",
  "logs": "string (optional)"
}
```

## 5. Environment Variables

### GitHub Actions
```yaml
env:
  DASHBOARD_URL: ${{ secrets.DASHBOARD_URL || 'http://localhost:4000' }}
```

### Jenkins
```groovy
environment {
    DASHBOARD_URL = env.DASHBOARD_URL ?: 'http://localhost:4000'
}
```

## 6. Testing Locally

### Start the Dashboard
```bash
# Backend
cd backend && npm start

# Frontend
cd frontend && npm run dev
```

### Test Webhooks
```bash
# Test GitHub Actions webhook
curl -X POST http://localhost:4000/api/webhook/gha \
  -H "Content-Type: application/json" \
  -d '{
    "pipelineName": "test-pipeline",
    "status": "success",
    "startedAt": "2024-01-01T10:00:00Z",
    "finishedAt": "2024-01-01T10:05:00Z",
    "durationMs": 300000,
    "branch": "main",
    "commitSha": "abc123",
    "triggeredBy": "test-user",
    "logs": "Test completed successfully"
  }'

# Test Jenkins webhook
curl -X POST http://localhost:4000/api/webhook/jenkins \
  -H "Content-Type: application/json" \
  -d '{
    "pipelineName": "jenkins-test",
    "status": "success",
    "startedAt": "2024-01-01T10:00:00Z",
    "finishedAt": "2024-01-01T10:05:00Z",
    "durationMs": 300000,
    "branch": "main",
    "commitSha": "abc123",
    "triggeredBy": "jenkins",
    "logs": "Jenkins pipeline completed"
  }'
```

## 7. Production Deployment

### Option 1: Docker Deployment
```bash
# Deploy using Docker Compose
docker compose up --build -d
```

### Option 2: Manual Deployment
1. Deploy backend to your server
2. Deploy frontend to your web server
3. Update `DASHBOARD_URL` in your CI/CD tools to point to your production URL

## 8. Troubleshooting

### Common Issues
1. **Webhook not received**: Check firewall settings and ensure the dashboard URL is accessible
2. **CORS errors**: Ensure CORS is properly configured in the backend
3. **Authentication**: Add authentication if needed for production use

### Debug Steps
1. Check dashboard logs for incoming webhook requests
2. Verify webhook URLs are correct
3. Test webhooks manually using curl
4. Check CI/CD tool logs for webhook sending errors

## 9. Security Considerations

### For Production
1. Add authentication to webhook endpoints
2. Use HTTPS for all communications
3. Validate webhook payloads
4. Implement rate limiting
5. Add IP whitelisting if needed

### Example: Adding Basic Auth
```javascript
// In backend/src/index.js
app.use('/api/webhook/*', (req, res, next) => {
  const auth = req.headers.authorization;
  if (auth !== `Bearer ${process.env.WEBHOOK_SECRET}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
});
```
