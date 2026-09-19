import http from 'k6/http';
import { check, sleep } from 'k6';

const targetUrl = __ENV.STAGING_BASE_URL;

// Validate required staging URL.
if (!targetUrl) {
  throw new Error('STAGING_BASE_URL environment variable is required');
}

const urlPattern = /^https?:\/\/[^/\s?#]+(?:[/?#]|$)/i;

if (!urlPattern.test(targetUrl.trim())) {
  throw new Error(
    `STAGING_BASE_URL must be a valid HTTP or HTTPS URL. Received: ${targetUrl}`
  );
}

// Load configuration with environment-variable overrides.
const rampUpDuration = __ENV.K6_RAMP_UP_DURATION || '10s';
const rampUpTarget = Number(__ENV.K6_RAMP_UP_TARGET || 5);

const steadyDuration = __ENV.K6_STEADY_DURATION || '30s';
const steadyTarget = Number(__ENV.K6_STEADY_TARGET || 10);

const rampDownDuration = __ENV.K6_RAMP_DOWN_DURATION || '10s';
const rampDownTarget = Number(__ENV.K6_RAMP_DOWN_TARGET || 0);

// Validate numeric load settings.
if (
  !Number.isInteger(rampUpTarget) ||
  rampUpTarget < 0 ||
  !Number.isInteger(steadyTarget) ||
  steadyTarget < 0 ||
  !Number.isInteger(rampDownTarget) ||
  rampDownTarget < 0
) {
  throw new Error(
    'K6_RAMP_UP_TARGET, K6_STEADY_TARGET, and K6_RAMP_DOWN_TARGET must be non-negative integers'
  );
}

// Expected HTTP responses are 2xx and 3xx.
// 4xx, 5xx, and transport errors are counted as failed requests.
http.setResponseCallback(
  http.expectedStatuses({ min: 200, max: 399 })
);

export const options = {
  stages: [
    {
      duration: rampUpDuration,
      target: rampUpTarget,
    },
    {
      duration: steadyDuration,
      target: steadyTarget,
    },
    {
      duration: rampDownDuration,
      target: rampDownTarget,
    },
  ],

  thresholds: {
    // 95% of requests should complete within 2 seconds.
    http_req_duration: ['p(95)<2000'],

    // Fewer than 5% of requests may fail.
    // HTTP 4xx/5xx responses and transport errors are considered failures.
    http_req_failed: ['rate<0.05'],
  },
};

export default function () {
  const response = http.get(targetUrl);

  check(response, {
    'response status is successful (2xx/3xx)': (r) =>
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