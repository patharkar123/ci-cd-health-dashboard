## Technical Design

### Architecture
- Client (React) → REST (Express) for metrics and recent builds
- Client subscribes to SSE `/api/events/stream` for live updates
- Storage: SQLite with table `pipeline_runs`
- Alerts: Slack webhook fired on failure
- Optional demo generator inserts synthetic runs periodically

### API Routes
- GET `/api/metrics/summary`
  - Response: `{ totalRuns, successRate, failureRate, running, averageBuildTimeMs, lastBuildStatus, lastBuildPipeline, lastBuildStartedAt, lastBuildFinishedAt }`
- GET `/api/builds/latest?limit=20`
  - Response: `{ items: Run[] }`
- GET `/api/events/stream`
  - SSE: events `ready`, `run.created`
- POST `/api/webhook/gha`
- POST `/api/webhook/jenkins`
  - Request: `{ pipelineName, status, durationMs?, startedAt?, finishedAt?, branch?, commitSha?, triggeredBy?, logs? }`
  - Status: one of `success|failure|running|queued`

### DB Schema
Table: `pipeline_runs`
- `id` INTEGER PK
- `provider` TEXT
- `pipeline_name` TEXT
- `status` TEXT CHECK in (success,failure,running,queued)
- `duration_ms` INTEGER NULL
- `started_at` TEXT (ISO)
- `finished_at` TEXT NULL
- `branch` TEXT NULL
- `commit_sha` TEXT NULL
- `triggered_by` TEXT NULL
- `logs` TEXT NULL

### UI Layout
- Header: title
- Grid: 4 metric cards (success, failure, avg time, last status)
- Table: latest builds with status pills
- SSE indicator

### Deployment
- Dockerfiles for backend and frontend
- docker-compose for local dev
- Volume for SQLite persistence

### Security & Ops (Future Work)
- AuthN/Z for API and UI
- Rate limits and webhook validation
- Email alert provider or PagerDuty integration
- Migrate to Postgres for multi-user/team scale

