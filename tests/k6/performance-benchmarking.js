import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import Papa from 'https://jslib.k6.io/papaparse/5.1.1/index.js';
import { Trend, Rate, Counter } from 'k6/metrics';

export const options = {
  vus: 10,
  duration: '1m',
  thresholds: {
    http_req_failed: ['rate<0.05'],
  },
};

// =====================
// LOAD CSV
// =====================

const apiData = new SharedArray('apiData', function () {

  const parsed = Papa.parse(open('./api.csv'), {
    header: true,
    skipEmptyLines: true,
  }).data;

  console.log('CSV CONTENTS:');
  console.log(JSON.stringify(parsed));

  parsed.forEach((row, index) => {
    if (!row.api_name || !row.method || !row.url) {
      throw new Error(
        `CSV row ${index + 1} is missing api_name, method, or url`
      );
    }
  });

  return parsed;
});

// =====================
// METRICS
// =====================

const apiMetrics = {};

apiData.forEach(api => {
  apiMetrics[api.api_name] = {
    latency: new Trend(`${api.api_name}_latency`),
    errors: new Rate(`${api.api_name}_errors`),
    requests: new Counter(`${api.api_name}_requests`)
  };
});

// =====================
// AUTH CONFIG
// =====================

const AUTH_URL = __ENV.AUTH_URL;
const CLIENT_ID = __ENV.CLIENT_ID;
const USERNAME = __ENV.USERNAME;
const PASSWORD = __ENV.PASSWORD;

// =====================
// GET TOKEN
// =====================

function getToken() {

  const authPayload = JSON.stringify({
    AuthFlow: 'USER_PASSWORD_AUTH',
    ClientId: CLIENT_ID,
    AuthParameters: {
      USERNAME,
      PASSWORD
    }
  });

  const authHeaders = {
    'Content-Type': 'application/x-amz-json-1.1',
    'X-Amz-Target':
      'AWSCognitoIdentityProviderService.InitiateAuth'
  };

  const authRes = http.post(
    AUTH_URL,
    authPayload,
    { headers: authHeaders }
  );

  console.log(`AUTH STATUS: ${authRes.status}`);
  console.log(`AUTH RESPONSE: ${authRes.body}`);

  check(authRes, {
    'auth success': r => r.status === 200
  });

  const token =
    authRes.json('AuthenticationResult.IdToken');

  console.log(`TOKEN FOUND: ${!!token}`);

  return token;
}

// =====================
// MAIN TEST
// =====================

export default function () {

  const token = getToken();

  if (!token) {

    console.error(
      'No token returned from Cognito. Skipping iteration.'
    );

    return;
  }

  for (const api of apiData) {

    if (
      !api.url ||
      api.url.trim() === '' ||
      api.url === '#<nil>'
    ) {
      console.error(
        `Skipping ${api.api_name} due to invalid URL`
      );
      continue;
    }

    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    };

    let payload = null;

    if (
      ['POST', 'PUT', 'PATCH']
        .includes(api.method.toUpperCase())
    ) {

      if (
        api.payload &&
        api.payload.trim() !== ''
      ) {

        payload = api.payload
          .replace(/""/g, '"');

        // remove wrapping quotes

        if (
          payload.startsWith('"') &&
          payload.endsWith('"')
        ) {
          payload = payload.slice(1, -1);
        }
      }
    }

    console.log('===============================');
    console.log(`API NAME: ${api.api_name}`);
    console.log(`METHOD: ${api.method}`);
    console.log(`URL: ${api.url}`);
    console.log(`PAYLOAD: ${payload}`);
    console.log('===============================');

    const res = http.request(
      api.method,
      api.url.trim(),
      payload,
      { headers }
    );

    console.log(`STATUS: ${res.status}`);
    console.log(`RESPONSE BODY: ${res.body}`);

    apiMetrics[api.api_name]
      .latency
      .add(res.timings.duration);

    apiMetrics[api.api_name]
      .errors
      .add(res.status !== 200);

    apiMetrics[api.api_name]
      .requests
      .add(1);

    check(res, {
      'status is 200': r => r.status === 200
    });

    sleep(0.2);
  }
}
