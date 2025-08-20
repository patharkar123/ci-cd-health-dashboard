import axios from 'axios';

export async function sendFailureAlert(run) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  if (!webhookUrl) return;
  const text = `CI/CD Failure: ${run.pipelineName} (${run.provider}) on ${run.branch || 'unknown branch'}\n` +
               `Status: ${run.status}\n` +
               `Duration: ${run.durationMs ? Math.round(run.durationMs/1000) + 's' : 'n/a'}\n` +
               `${run.commitSha ? 'Commit: ' + run.commitSha + "\n" : ''}` +
               `${run.triggeredBy ? 'By: ' + run.triggeredBy + "\n" : ''}` +
               `${run.logs ? 'Logs: ' + (run.logs.slice(0, 2000)) : ''}`;
  try {
    await axios.post(webhookUrl, { text });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('Failed to send Slack alert', err.message);
  }
}

