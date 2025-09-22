#!/bin/bash
# User Data Script for CI/CD Dashboard Deployment
# Generated with AI assistance (Cursor)
# This script runs on EC2 instance startup to install and configure the application

set -e

# Log everything
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting CI/CD Dashboard deployment setup..."

# Update system
yum update -y

# Install Git
yum install -y git

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create application directory
mkdir -p /opt/cicd-dashboard
cd /opt/cicd-dashboard

# Clone the repository (you'll need to update this URL)
# For now, we'll create the application files directly
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      - PORT=4000
      - DATABASE_FILE=./backend/data/health_dashboard.sqlite
      - CORS_ORIGIN=*
      - SLACK_WEBHOOK_URL=
      - DEMO_MODE=true
      - EMAIL_FROM=
      - EMAIL_TO=
      - EMAIL_PASSWORD=
      - EMAIL_HOST=smtp.gmail.com
      - EMAIL_PORT=587
    ports:
      - "4000:4000"
    volumes:
      - ./backend/data:/app/data
    restart: unless-stopped
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        VITE_API_BASE: "http://localhost:4000"
    ports:
      - "8080:80"
    depends_on:
      - backend
    restart: unless-stopped
EOF

# Create backend directory structure
mkdir -p backend/src backend/data
cd backend

# Create package.json for backend
cat > package.json << 'EOF'
{
  "name": "ci-cd-health-dashboard-backend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "NODE_ENV=development nodemon src/index.js"
  },
  "dependencies": {
    "axios": "^1.6.8",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "nodemailer": "^7.0.5"
  },
  "devDependencies": {
    "nodemon": "^3.1.0"
  }
}
EOF

# Create Dockerfile for backend
cat > Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci || npm i --production
COPY . .
ENV NODE_ENV=production
EXPOSE 4000
CMD ["node", "src/index.js"]
EOF

# Create backend source files
cat > src/index.js << 'EOF'
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import { insertPipelineRun, getLatestRuns, getSummary } from './db.js';
import { sendFailureAlert, testEmailConnection } from './alert.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json({ limit: '2mb' }));
app.use(cors({ origin: process.env.CORS_ORIGIN || '*'}));

// SSE clients
const sseClients = new Set();
function broadcastEvent(eventType, data) {
  const payload = `event: ${eventType}\ndata: ${JSON.stringify(data)}\n\n`;
  for (const res of sseClients) {
    res.write(payload);
  }
}

// API routes
app.get('/api/metrics/summary', async (req, res) => {
  try {
    const summary = await getSummary();
    res.json(summary);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/builds/latest', async (req, res) => {
  try {
    const limit = Number(req.query.limit || 20);
    const items = await getLatestRuns(limit);
    res.json({ items });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/events/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders?.();
  sseClients.add(res);
  res.write(`event: ready\ndata: {"ok": true}\n\n`);
  req.on('close', () => sseClients.delete(res));
});

function normalizeRun(provider, body) {
  const now = new Date();
  const startedAt = body.startedAt || now.toISOString();
  const finishedAt = body.finishedAt || (body.status === 'running' || body.status === 'queued' ? null : now.toISOString());
  const durationMs = body.durationMs ?? (finishedAt ? Math.max(0, new Date(finishedAt) - new Date(startedAt)) : null);
  return {
    provider,
    pipelineName: body.pipelineName || body.workflow || body.jobName || 'unknown',
    status: body.status,
    durationMs,
    startedAt,
    finishedAt,
    branch: body.branch,
    commitSha: body.commitSha,
    triggeredBy: body.triggeredBy,
    logs: body.logs
  };
}

app.post('/api/webhook/gha', async (req, res) => {
  try {
    const payload = normalizeRun('github-actions', req.body || {});
    if (!payload.status) return res.status(400).json({ error: 'status is required' });
    const id = await insertPipelineRun(payload);
    broadcastEvent('run.created', { id, ...payload });
    if (payload.status === 'failure') {
      sendFailureAlert(payload).catch(() => {});
    }
    res.json({ ok: true, id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/webhook/jenkins', async (req, res) => {
  try {
    const payload = normalizeRun('jenkins', req.body || {});
    if (!payload.status) return res.status(400).json({ error: 'status is required' });
    const id = await insertPipelineRun(payload);
    broadcastEvent('run.created', { id, ...payload });
    if (payload.status === 'failure') {
      sendFailureAlert(payload).catch(() => {});
    }
    res.json({ ok: true, id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const publicDir = path.join(__dirname, '../public');
app.use(express.static(publicDir));

app.get('/api/health', (req, res) => res.json({ ok: true }));

app.get('/api/test-email', async (req, res) => {
  try {
    const isConnected = await testEmailConnection();
    res.json({ 
      ok: true, 
      emailConnection: isConnected,
      message: isConnected ? 'Email server connected successfully' : 'Email server connection failed'
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/test-email-alert', async (req, res) => {
  try {
    const testRun = {
      pipelineName: 'test-pipeline',
      provider: 'test-provider',
      status: 'failure',
      startedAt: new Date().toISOString(),
      finishedAt: new Date().toISOString(),
      durationMs: 60000,
      branch: 'test-branch',
      commitSha: 'test123',
      triggeredBy: 'test-user',
      logs: 'This is a test failure log for email notification testing.'
    };
    
    await sendFailureAlert(testRun);
    res.json({ ok: true, message: 'Test email alert sent successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const port = Number(process.env.PORT || 4000);

if (String(process.env.DEMO_MODE || 'true') === 'true') {
  const statuses = ['success', 'failure'];
  const pipelines = ['build-and-test', 'deploy-staging', 'lint-and-typecheck'];
  setInterval(async () => {
    const now = new Date();
    const duration = Math.floor(30_000 + Math.random() * 180_000);
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    const run = {
      provider: Math.random() > 0.5 ? 'github-actions' : 'jenkins',
      pipelineName: pipelines[Math.floor(Math.random() * pipelines.length)],
      status,
      durationMs: duration,
      startedAt: new Date(now.getTime() - duration).toISOString(),
      finishedAt: now.toISOString(),
      branch: Math.random() > 0.5 ? 'main' : 'feature/demo',
      commitSha: Math.random().toString(16).slice(2, 9),
      triggeredBy: Math.random() > 0.5 ? 'ci-bot' : 'developer',
      logs: status === 'failure' ? 'Error: unit tests failed in module X' : 'All checks passed.'
    };
    try {
      const id = await insertPipelineRun(run);
      broadcastEvent('run.created', { id, ...run });
      if (run.status === 'failure') {
        sendFailureAlert(run).catch(() => {});
      }
    } catch (err) {
      console.error('Demo data generation error:', err);
    }
  }, 20_000);
}

app.listen(port, () => {
  console.log(`API listening on http://localhost:${port}`);
});
EOF

cat > src/db.js << 'EOF'
// Simple in-memory storage for demo
const runs = [];
let nextId = 1;

export function insertPipelineRun(run) {
  return new Promise((resolve) => {
    const id = nextId++;
    const runWithId = { id, ...run };
    runs.unshift(runWithId);
    if (runs.length > 100) {
      runs.splice(100);
    }
    resolve(id);
  });
}

export function getLatestRuns(limit = 20) {
  return new Promise((resolve) => {
    resolve(runs.slice(0, limit));
  });
}

export function getSummary() {
  return new Promise((resolve) => {
    const total = runs.length;
    const successes = runs.filter(r => r.status === 'success').length;
    const failures = runs.filter(r => r.status === 'failure').length;
    const running = runs.filter(r => r.status === 'running').length;
    
    const completedRuns = runs.filter(r => r.durationMs != null);
    const avgDurationMs = completedRuns.length > 0 
      ? Math.round(completedRuns.reduce((sum, r) => sum + r.durationMs, 0) / completedRuns.length)
      : null;
    
    const lastRun = runs[0] || null;
    const successRate = total > 0 ? Math.round((successes / total) * 100) : 0;
    
    resolve({
      totalRuns: total,
      successRate,
      failureRate: total > 0 ? Math.round((failures / total) * 100) : 0,
      running,
      averageBuildTimeMs: avgDurationMs,
      lastBuildStatus: lastRun ? lastRun.status : null,
      lastBuildPipeline: lastRun ? lastRun.pipelineName : null,
      lastBuildStartedAt: lastRun ? lastRun.startedAt : null,
      lastBuildFinishedAt: lastRun ? lastRun.finishedAt : null
    });
  });
}

export default { runs };
EOF

cat > src/alert.js << 'EOF'
import nodemailer from 'nodemailer';

export async function testEmailConnection() {
  try {
    if (!process.env.EMAIL_FROM || !process.env.EMAIL_PASSWORD) {
      return false;
    }
    
    const transporter = nodemailer.createTransporter({
      host: process.env.EMAIL_HOST || 'smtp.gmail.com',
      port: Number(process.env.EMAIL_PORT || 587),
      secure: false,
      auth: {
        user: process.env.EMAIL_FROM,
        pass: process.env.EMAIL_PASSWORD,
      },
    });

    await transporter.verify();
    return true;
  } catch (error) {
    console.error('Email connection test failed:', error);
    return false;
  }
}

export async function sendFailureAlert(run) {
  try {
    if (!process.env.EMAIL_FROM || !process.env.EMAIL_TO || !process.env.EMAIL_PASSWORD) {
      console.log('Email not configured, skipping alert');
      return;
    }

    const transporter = nodemailer.createTransporter({
      host: process.env.EMAIL_HOST || 'smtp.gmail.com',
      port: Number(process.env.EMAIL_PORT || 587),
      secure: false,
      auth: {
        user: process.env.EMAIL_FROM,
        pass: process.env.EMAIL_PASSWORD,
      },
    });

    const subject = `CI/CD Failure Alert: ${run.pipelineName}`;
    const text = `
Pipeline Failure Detected!

Pipeline: ${run.pipelineName}
Provider: ${run.provider}
Status: ${run.status}
Branch: ${run.branch || 'unknown'}
Duration: ${run.durationMs ? Math.round(run.durationMs / 1000) + 's' : 'unknown'}
Triggered by: ${run.triggeredBy || 'unknown'}
Started: ${run.startedAt || 'unknown'}
Finished: ${run.finishedAt || 'unknown'}

Logs:
${run.logs || 'No logs available'}
    `;

    await transporter.sendMail({
      from: process.env.EMAIL_FROM,
      to: process.env.EMAIL_TO,
      subject,
      text,
    });

    console.log('Failure alert sent successfully');
  } catch (error) {
    console.error('Failed to send failure alert:', error);
  }
}
EOF

# Move to frontend directory
cd /opt/cicd-dashboard
mkdir -p frontend/src
cd frontend

# Create package.json for frontend
cat > package.json << 'EOF'
{
  "name": "ci-cd-health-dashboard-frontend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.0",
    "vite": "^5.3.3"
  }
}
EOF

# Create Dockerfile for frontend
cat > Dockerfile << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci || npm i
COPY . .
ARG VITE_API_BASE=http://localhost:4000
ENV VITE_API_BASE=${VITE_API_BASE}
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Create basic React app structure
cat > index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>CI/CD Pipeline Health Dashboard</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173
  }
})
EOF

# Create React components
cat > src/main.jsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

cat > src/App.jsx << 'EOF'
import React, { useState, useEffect } from 'react';

const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:4000';

function App() {
  const [metrics, setMetrics] = useState(null);
  const [builds, setBuilds] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchData = async () => {
    try {
      const [metricsRes, buildsRes] = await Promise.all([
        fetch(`${API_BASE}/api/metrics/summary`),
        fetch(`${API_BASE}/api/builds/latest?limit=20`)
      ]);
      
      const metricsData = await metricsRes.json();
      const buildsData = await buildsRes.json();
      
      setMetrics(metricsData);
      setBuilds(buildsData.items || []);
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch data:', error);
      setLoading(false);
    }
  };

  if (loading) {
    return <div style={{ padding: '20px' }}>Loading...</div>;
  }

  return (
    <div style={{ 
      fontFamily: 'Arial, sans-serif', 
      padding: '20px',
      backgroundColor: '#f5f5f5',
      minHeight: '100vh'
    }}>
      <h1 style={{ color: '#333', marginBottom: '30px' }}>
        CI/CD Pipeline Health Dashboard
      </h1>
      
      {metrics && (
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
          gap: '20px',
          marginBottom: '30px'
        }}>
          <div style={{
            backgroundColor: 'white',
            padding: '20px',
            borderRadius: '8px',
            boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
          }}>
            <h3 style={{ margin: '0 0 10px 0', color: '#666' }}>Success Rate</h3>
            <p style={{ 
              fontSize: '24px', 
              margin: 0, 
              color: metrics.successRate >= 80 ? '#28a745' : '#dc3545'
            }}>
              {metrics.successRate}%
            </p>
          </div>
          
          <div style={{
            backgroundColor: 'white',
            padding: '20px',
            borderRadius: '8px',
            boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
          }}>
            <h3 style={{ margin: '0 0 10px 0', color: '#666' }}>Total Runs</h3>
            <p style={{ fontSize: '24px', margin: 0, color: '#333' }}>
              {metrics.totalRuns}
            </p>
          </div>
          
          <div style={{
            backgroundColor: 'white',
            padding: '20px',
            borderRadius: '8px',
            boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
          }}>
            <h3 style={{ margin: '0 0 10px 0', color: '#666' }}>Avg Build Time</h3>
            <p style={{ fontSize: '24px', margin: 0, color: '#333' }}>
              {metrics.averageBuildTimeMs 
                ? `${Math.round(metrics.averageBuildTimeMs / 1000)}s`
                : 'N/A'
              }
            </p>
          </div>
          
          <div style={{
            backgroundColor: 'white',
            padding: '20px',
            borderRadius: '8px',
            boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
          }}>
            <h3 style={{ margin: '0 0 10px 0', color: '#666' }}>Last Build</h3>
            <p style={{ 
              fontSize: '18px', 
              margin: 0,
              color: metrics.lastBuildStatus === 'success' ? '#28a745' : 
                     metrics.lastBuildStatus === 'failure' ? '#dc3545' : '#ffc107'
            }}>
              {metrics.lastBuildStatus || 'N/A'}
            </p>
          </div>
        </div>
      )}
      
      <div style={{
        backgroundColor: 'white',
        padding: '20px',
        borderRadius: '8px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
      }}>
        <h2 style={{ marginTop: 0, color: '#333' }}>Recent Builds</h2>
        
        {builds.length === 0 ? (
          <p>No builds found. Demo mode will generate builds automatically.</p>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ 
              width: '100%', 
              borderCollapse: 'collapse',
              fontSize: '14px'
            }}>
              <thead>
                <tr style={{ backgroundColor: '#f8f9fa' }}>
                  <th style={{ padding: '12px', textAlign: 'left', borderBottom: '1px solid #dee2e6' }}>Pipeline</th>
                  <th style={{ padding: '12px', textAlign: 'left', borderBottom: '1px solid #dee2e6' }}>Provider</th>
                  <th style={{ padding: '12px', textAlign: 'left', borderBottom: '1px solid #dee2e6' }}>Status</th>
                  <th style={{ padding: '12px', textAlign: 'left', borderBottom: '1px solid #dee2e6' }}>Duration</th>
                  <th style={{ padding: '12px', textAlign: 'left', borderBottom: '1px solid #dee2e6' }}>Branch</th>
                  <th style={{ padding: '12px', textAlign: 'left', borderBottom: '1px solid #dee2e6' }}>Started</th>
                </tr>
              </thead>
              <tbody>
                {builds.map((build, index) => (
                  <tr key={build.id || index}>
                    <td style={{ padding: '12px', borderBottom: '1px solid #dee2e6' }}>
                      {build.pipelineName}
                    </td>
                    <td style={{ padding: '12px', borderBottom: '1px solid #dee2e6' }}>
                      {build.provider}
                    </td>
                    <td style={{ 
                      padding: '12px', 
                      borderBottom: '1px solid #dee2e6',
                      color: build.status === 'success' ? '#28a745' : 
                             build.status === 'failure' ? '#dc3545' : '#ffc107'
                    }}>
                      {build.status}
                    </td>
                    <td style={{ padding: '12px', borderBottom: '1px solid #dee2e6' }}>
                      {build.durationMs ? `${Math.round(build.durationMs / 1000)}s` : 'N/A'}
                    </td>
                    <td style={{ padding: '12px', borderBottom: '1px solid #dee2e6' }}>
                      {build.branch || 'N/A'}
                    </td>
                    <td style={{ padding: '12px', borderBottom: '1px solid #dee2e6' }}>
                      {build.startedAt ? new Date(build.startedAt).toLocaleString() : 'N/A'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
EOF

# Set proper ownership
chown -R ec2-user:ec2-user /opt/cicd-dashboard

# Build and start the application
cd /opt/cicd-dashboard
docker-compose up --build -d

echo "CI/CD Dashboard deployment completed!"
echo "Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):4000"
echo "Setup completed at $(date)"
