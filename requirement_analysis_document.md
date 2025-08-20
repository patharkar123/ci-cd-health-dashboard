## Requirement Analysis

### Goals
- Monitor CI/CD pipeline executions with success/failure, duration, and status.
- Provide real-time metrics and latest builds.
- Alert on failures via Slack/Email (Slack implemented).
- Simple frontend UI for visualization and recent build logs/status.

### Key Features
- Data ingestion endpoints for GitHub Actions and Jenkins.
- Metrics: success/failure rate, average build time, last build status.
- Real-time updates via SSE.
- Alerts on failures via Slack webhook.
- Storage of runs in SQLite for simplicity.
- Demo data generator to simulate pipelines.

### Use Cases
- SRE/Dev leads monitor deployment health at a glance.
- Investigate recent failed runs and durations.
- Receive immediate Slack notifications on failures.

### Tech Choices
- Node.js + Express for rapid API development and SSE support.
- SQLite (better-sqlite3) for embedded, simple persistence.
- React + Vite for a minimal, responsive UI.
- Slack Incoming Webhook for alerts; can add SMTP later.
- Docker for consistent deployment.

### Constraints & Assumptions
- No auth required for demo; add auth in production.
- Runs are appended; no complex relations needed.
- SSE is sufficient for real-time; WebSocket could be added if needed.
- Email alerts are out-of-scope for this iteration.

