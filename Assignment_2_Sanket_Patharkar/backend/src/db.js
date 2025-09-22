// Simple in-memory storage for demo
const runs = [];
let nextId = 1;

export function insertPipelineRun(run) {
  return new Promise((resolve) => {
    const id = nextId++;
    const runWithId = { id, ...run };
    runs.unshift(runWithId);
    // Keep only last 100 runs
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

