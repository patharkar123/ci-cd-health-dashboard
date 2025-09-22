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
  // Expecting minimal shape, map external payloads if needed
  const now = new Date();
  const startedAt = body.startedAt || now.toISOString();
  const finishedAt = body.finishedAt || (body.status === 'running' || body.status === 'queued' ? null : now.toISOString());
  const durationMs = body.durationMs ?? (finishedAt ? Math.max(0, new Date(finishedAt) - new Date(startedAt)) : null);
  return {
    provider,
    pipelineName: body.pipelineName || body.workflow || body.jobName || 'unknown',
    status: body.status, // expected: success|failure|running|queued
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

// Serve static frontend (optional: if frontend build is copied into backend/public)
const publicDir = path.join(__dirname, '../public');
app.use(express.static(publicDir));

// Simple health
app.get('/api/health', (req, res) => res.json({ ok: true }));

// Test email connection
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

// Test email alert
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

// Demo mode: generate synthetic runs periodically
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
  // eslint-disable-next-line no-console
  console.log(`API listening on http://localhost:${port}`);
});


