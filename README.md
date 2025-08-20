# See `README.md`

This file exists to satisfy submission naming requirements. Please read `README.md` for full instructions and documentation.
## CI/CD Pipeline Health Dashboard

Monitors CI/CD executions (GitHub Actions/Jenkins) with real-time metrics, recent builds, and failure alerts via Slack. Includes demo data generator, API, React UI, and Docker setup.

### Features
- Success/Failure rate, average build time, last build status
- Latest builds table with provider, pipeline, duration, branch, commit, actor
- Real-time updates via Server-Sent Events (SSE)
- Slack alerts on failures
- Demo mode to simulate runs

### Tech Stack
- Backend: Node.js, Express, SQLite (better-sqlite3)
- Frontend: React + Vite
- Realtime: SSE
- Alerts: Slack Incoming Webhook
- Container: Docker, docker-compose

### Quick Start (Local)
1. Backend
```
cd backend
npm i
cp env.example .env
npm run start
```
2. Frontend
```
cd frontend
npm i
npm run dev
```
Open `http://localhost:5173`.

### Docker
```
docker compose up --build
```
- API at `http://localhost:4000`
- Frontend at `http://localhost:8080`

### API Overview
- GET `/api/metrics/summary` → overall metrics
- GET `/api/builds/latest?limit=20` → recent builds
- GET `/api/events/stream` → SSE stream
- POST `/api/webhook/gha` → upsert run from GitHub Actions payload
- POST `/api/webhook/jenkins` → upsert run from Jenkins payload

Payload shape example:
```json
{
  "pipelineName": "build-and-test",
  "status": "success",
  "durationMs": 90000,
  "startedAt": "2024-01-01T10:00:00Z",
  "finishedAt": "2024-01-01T10:01:30Z",
  "branch": "main",
  "commitSha": "abcdef1",
  "triggeredBy": "ci-bot",
  "logs": "...optional log text..."
}
```

### Slack Alert
Set `SLACK_WEBHOOK_URL` in `backend/.env`. Failures post a message containing pipeline name, status, duration, branch, and log snippet.

### Docs in Repo
- `prompot_logs.md`
- `requirement_analysis_document.md`
- `tech_design_document.md`

### Notes
- Demo mode is enabled by default (`DEMO_MODE=true`) to generate synthetic runs every ~20s. Disable in `.env` for production.

