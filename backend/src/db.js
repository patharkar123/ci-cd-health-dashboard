import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';

const dataDir = path.join(process.cwd(), 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

const dbFile = process.env.DATABASE_FILE || path.join(dataDir, 'health_dashboard.sqlite');
const db = new Database(dbFile);

db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS pipeline_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider TEXT NOT NULL,
    pipeline_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('success', 'failure', 'running', 'queued')),
    duration_ms INTEGER,
    started_at TEXT NOT NULL,
    finished_at TEXT,
    branch TEXT,
    commit_sha TEXT,
    triggered_by TEXT,
    logs TEXT
  );
`);

export function insertPipelineRun(run) {
  const stmt = db.prepare(`
    INSERT INTO pipeline_runs (
      provider, pipeline_name, status, duration_ms, started_at, finished_at,
      branch, commit_sha, triggered_by, logs
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const info = stmt.run(
    run.provider,
    run.pipelineName,
    run.status,
    run.durationMs ?? null,
    run.startedAt,
    run.finishedAt ?? null,
    run.branch ?? null,
    run.commitSha ?? null,
    run.triggeredBy ?? null,
    run.logs ?? null
  );
  return info.lastInsertRowid;
}

export function getLatestRuns(limit = 20) {
  const stmt = db.prepare(`
    SELECT id, provider, pipeline_name as pipelineName, status, duration_ms as durationMs,
           started_at as startedAt, finished_at as finishedAt, branch, commit_sha as commitSha,
           triggered_by as triggeredBy, logs
    FROM pipeline_runs
    ORDER BY started_at DESC
    LIMIT ?
  `);
  return stmt.all(limit);
}

export function getSummary() {
  const total = db.prepare('SELECT COUNT(*) as c FROM pipeline_runs').get().c;
  const successes = db.prepare("SELECT COUNT(*) as c FROM pipeline_runs WHERE status = 'success'").get().c;
  const failures = db.prepare("SELECT COUNT(*) as c FROM pipeline_runs WHERE status = 'failure'").get().c;
  const running = db.prepare("SELECT COUNT(*) as c FROM pipeline_runs WHERE status = 'running'").get().c;
  const avgDurationRow = db.prepare('SELECT AVG(duration_ms) as avgMs FROM pipeline_runs WHERE duration_ms IS NOT NULL').get();
  const avgDurationMs = avgDurationRow.avgMs ? Math.round(avgDurationRow.avgMs) : null;
  const lastRun = db.prepare(`
    SELECT status, started_at as startedAt, finished_at as finishedAt, pipeline_name as pipelineName
    FROM pipeline_runs
    ORDER BY started_at DESC
    LIMIT 1
  `).get();
  const successRate = total > 0 ? Math.round((successes / total) * 100) : 0;
  return {
    totalRuns: total,
    successRate,
    failureRate: total > 0 ? Math.round((failures / total) * 100) : 0,
    running,
    averageBuildTimeMs: avgDurationMs,
    lastBuildStatus: lastRun ? lastRun.status : null,
    lastBuildPipeline: lastRun ? lastRun.pipelineName : null,
    lastBuildStartedAt: lastRun ? lastRun.startedAt : null,
    lastBuildFinishedAt: lastRun ? lastRun.finishedAt : null
  };
}

export default db;

