import http from 'k6/http';
import { check, sleep } from 'k6';

const targetUrl = __ENV.STAGING_BASE_URL;

if (!targetUrl) {
  throw new Error('STAGING_BASE_URL environment variable is required');
}

export const options = {
  stages: [
    { duration: '10s', target: 5 },
    { duration: '30s', target: 10 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],
    http_req_failed: ['rate<0.05'],
  },
};

export default function () {
  const response = http.get(targetUrl);

  check(response, {
    'response status is successful': (r) =>
      r.status >= 200 && r.status < 400,
  });

  sleep(1);
}

export function handleSummary(data) {
  return {
    'performance-results/summary.json': JSON.stringify(data, null, 2),
    stdout: JSON.stringify(
      {
        http_req_duration: data.metrics.http_req_duration,
        http_req_failed: data.metrics.http_req_failed,
        http_reqs: data.metrics.http_reqs,
      },
      null,
      2
    ),
  };
}