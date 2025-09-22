# Email Notification Setup Guide

## Overview
This guide explains how to set up email notifications for failed CI/CD builds using Gmail SMTP.

## Prerequisites
- Gmail account (hac.sank@gmail.com)
- 2-Factor Authentication enabled on your Google account

## Step-by-Step Setup

### 1. Enable 2-Factor Authentication
1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Navigate to **Security**
3. Enable **2-Step Verification** if not already enabled

### 2. Generate App Password
1. In Google Account Settings > Security
2. Find **App passwords** (under 2-Step Verification)
3. Click **Generate** for "Mail"
4. Copy the generated 16-character password

### 3. Update Environment Configuration
1. Copy `env.example` to `.env` in the backend directory
2. Update the email password:
   ```bash
   EMAIL_PASSWORD=your_16_character_app_password
   ```

### 4. Test Email Connection
```bash
# Test if email server can connect
curl http://localhost:4000/api/test-email

# Test sending a failure alert
curl -X POST http://localhost:4000/api/test-email-alert
```

## Email Configuration Details

### Current Settings
- **From**: hac.sank@gmail.com
- **To**: hac.sank@gmail.com
- **SMTP Host**: smtp.gmail.com
- **Port**: 587
- **Security**: TLS (STARTTLS)

### Environment Variables
```bash
EMAIL_FROM=hac.sank@gmail.com
EMAIL_TO=hac.sank@gmail.com
EMAIL_PASSWORD=your_app_password
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
```

## How It Works

### 1. Automatic Email Notifications
When a build fails, the system automatically:
- Sends an email to hac.sank@gmail.com
- Includes detailed build information
- Shows error logs and pipeline details

### 2. Email Content
The email includes:
- 🚨 Build failure alert header
- Pipeline details (name, provider, status)
- Branch and commit information
- Duration and timing details
- Error logs (if available)
- Timestamp of the alert

### 3. Integration Points
Email notifications are sent when:
- GitHub Actions builds fail
- Jenkins pipeline builds fail
- Demo data generates failures
- Manual test alerts are triggered

## Troubleshooting

### Common Issues

#### 1. "Email server connection failed"
- **Cause**: Incorrect app password or 2FA not enabled
- **Solution**: Generate a new app password and verify 2FA is enabled

#### 2. "Authentication failed"
- **Cause**: Wrong email or password
- **Solution**: Double-check email and app password

#### 3. "Connection timeout"
- **Cause**: Firewall or network issues
- **Solution**: Check network connectivity and firewall settings

### Debug Steps
1. Verify 2-Factor Authentication is enabled
2. Generate a new app password
3. Test connection: `curl http://localhost:4000/api/test-email`
4. Check container logs: `docker logs ci-cd-health-dashboard-backend-1`

## Security Notes

### Gmail App Passwords
- App passwords are more secure than regular passwords
- They can be revoked individually without affecting your main account
- Each app gets a unique password

### Production Considerations
- Use environment variables for sensitive data
- Consider using a dedicated email service for production
- Implement rate limiting for email notifications
- Add authentication to webhook endpoints

## Testing

### Test Email Connection
```bash
curl http://localhost:4000/api/test-email
```

### Test Email Alert
```bash
curl -X POST http://localhost:4000/api/test-email-alert
```

### Expected Response
```json
{
  "ok": true,
  "message": "Test email alert sent successfully"
}
```

## Next Steps

1. **Set up Gmail App Password** following the steps above
2. **Update your .env file** with the correct password
3. **Test the connection** using the test endpoints
4. **Trigger a build failure** to see the email notification in action

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify your Gmail account settings
3. Check the application logs for detailed error messages
4. Ensure all environment variables are correctly set
