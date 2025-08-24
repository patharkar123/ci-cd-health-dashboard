#!/bin/bash

echo "🚀 Setting up Real Email Notifications for CI/CD Dashboard"
echo "=========================================================="
echo ""

echo "📧 Email Configuration:"
echo "   From: hac.sank@gmail.com"
echo "   To: hac.sank@gmail.com"
echo "   SMTP: smtp.gmail.com:587"
echo ""

echo "🔐 To enable real emails, you need to:"
echo "   1. Enable 2-Factor Authentication on your Google account"
echo "   2. Generate an App Password for 'Mail'"
echo "   3. Update the docker-compose.yml file"
echo ""

echo "📋 Step-by-step instructions:"
echo "   1. Go to: https://myaccount.google.com/"
echo "   2. Security > 2-Step Verification > Enable"
echo "   3. Security > App passwords > Generate for 'Mail'"
echo "   4. Copy the 16-character password"
echo ""

echo "🔧 Update docker-compose.yml:"
echo "   Replace 'YOUR_GMAIL_APP_PASSWORD_HERE' with your actual app password"
echo ""

echo "✅ After updating, restart containers:"
echo "   docker compose down"
echo "   docker compose up -d"
echo ""

echo "🧪 Test real email:"
echo "   curl -X POST http://localhost:4000/api/test-email-alert"
echo ""

echo "📖 For detailed instructions, see: EMAIL_SETUP_GUIDE.md"
echo ""

read -p "Press Enter to continue..."
