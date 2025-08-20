import React, { useEffect, useMemo, useState } from 'react'

function formatMs(ms) {
  if (ms == null) return 'n/a'
  const s = Math.round(ms / 1000)
  if (s < 60) return `${s}s`
  const m = Math.floor(s / 60)
  const rem = s % 60
  return `${m}m ${rem}s`
}

export default function App() {
  const [summary, setSummary] = useState({})
  const [builds, setBuilds] = useState([])
  const [connected, setConnected] = useState(false)
  const API_BASE = import.meta.env.VITE_API_BASE || ''

  const statusPillClass = useMemo(() => ({
    success: 'pill success',
    failure: 'pill failure',
    running: 'pill running',
    queued: 'pill queued'
  }), [])

  async function load() {
    const s = await fetch(`${API_BASE}/api/metrics/summary`).then(r => r.json())
    const b = await fetch(`${API_BASE}/api/builds/latest?limit=20`).then(r => r.json())
    setSummary(s)
    setBuilds(b.items || [])
  }

  useEffect(() => {
    load()
    const ev = new EventSource(`${API_BASE}/api/events/stream`)
    ev.addEventListener('ready', () => setConnected(true))
    ev.addEventListener('run.created', (e) => {
      try {
        const data = JSON.parse(e.data)
        setBuilds(prev => [data, ...prev].slice(0, 20))
        fetch(`${API_BASE}/api/metrics/summary`).then(r => r.json()).then(setSummary)
      } catch {}
    })
    ev.onerror = () => setConnected(false)
    return () => ev.close()
  }, [])

  return (
    <div>
      <div className="grid">
        <div className="card">
          <div className="muted">Success Rate</div>
          <div style={{ fontSize: 28, marginTop: 6 }}>{summary.successRate ?? 0}%</div>
          <div className="footer">Total Runs: {summary.totalRuns ?? 0}</div>
        </div>
        <div className="card">
          <div className="muted">Failure Rate</div>
          <div style={{ fontSize: 28, marginTop: 6 }}>{summary.failureRate ?? 0}%</div>
          <div className="footer">Running: {summary.running ?? 0}</div>
        </div>
        <div className="card">
          <div className="muted">Average Build Time</div>
          <div style={{ fontSize: 28, marginTop: 6 }}>{formatMs(summary.averageBuildTimeMs)}</div>
          <div className="footer">Last: {summary.lastBuildPipeline || '—'}</div>
        </div>
        <div className="card">
          <div className="muted">Last Build Status</div>
          <div style={{ fontSize: 28, marginTop: 6 }}>
            {summary.lastBuildStatus ? (
              <span className={statusPillClass[summary.lastBuildStatus]}>{summary.lastBuildStatus}</span>
            ) : '—'}
          </div>
          <div className="footer">SSE: {connected ? 'Connected' : 'Disconnected'}</div>
        </div>
      </div>

      <div className="card" style={{ marginTop: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 style={{ margin: 0 }}>Latest Builds</h3>
          <button onClick={load} style={{ background: '#1f2937', color: '#e5e7eb', border: '1px solid #374151', borderRadius: 8, padding: '6px 10px', cursor: 'pointer' }}>Refresh</button>
        </div>
        <table>
          <thead>
            <tr>
              <th>When</th>
              <th>Provider</th>
              <th>Pipeline</th>
              <th>Status</th>
              <th>Duration</th>
              <th>Branch</th>
              <th>Commit</th>
              <th>By</th>
            </tr>
          </thead>
          <tbody>
            {builds.map((b) => (
              <tr key={b.id || b.startedAt + b.pipelineName}>
                <td className="muted">{new Date(b.startedAt).toLocaleString()}</td>
                <td>{b.provider}</td>
                <td>{b.pipelineName}</td>
                <td><span className={statusPillClass[b.status]}>{b.status}</span></td>
                <td>{formatMs(b.durationMs)}</td>
                <td className="muted">{b.branch || '—'}</td>
                <td className="muted">{b.commitSha || '—'}</td>
                <td className="muted">{b.triggeredBy || '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}


