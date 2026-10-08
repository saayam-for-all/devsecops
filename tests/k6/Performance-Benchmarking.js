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

const apiData = new SharedArray("apiData", function () {
  const parsed = Papa.parse(open('./api.csv'), {
    header: true,
    skipEmptyLines: true
  }).data;

  parsed.forEach((row, index) => {
    if (!row.api_name || !row.method || !row.url) {
      throw new Error(`CSV row ${index + 1} is missing required fields`);
    }
  });

  return parsed;
});

const apiMetrics = {};

apiData.forEach(api => {
  apiMetrics[api.api_name] = {
    latency: new Trend(`${api.api_name}_latency`),
    errors: new Rate(`${api.api_name}_errors`),
    requests: new Counter(`${api.api_name}_requests`)
  };
});

const AUTH_URL = __ENV.AUTH_URL;
const CLIENT_ID = __ENV.CLIENT_ID;
const USERNAME = __ENV.USERNAME;
const PASSWORD = __ENV.PASSWORD;

function getToken() {
  const authPayload = JSON.stringify({
    AuthFlow: "USER_PASSWORD_AUTH",
    ClientId: CLIENT_ID,
    AuthParameters: { USERNAME, PASSWORD }
  });

  const authHeaders = {
    'Content-Type': 'application/x-amz-json-1.1',
    'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth'
  };

  const authRes = http.post(AUTH_URL, authPayload, { headers: authHeaders });

  check(authRes, { 'auth success': (r) => r.status === 200 });

  return authRes.json('AuthenticationResult.IdToken');
}

export default function () {

  const token = getToken();

  for (const api of apiData) {

    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    };

    let payload = null;

    if (api.method === "POST" || api.method === "PUT") {
      payload = {};

      Object.keys(api).forEach(key => {
        if (!["api_name", "method", "url"].includes(key) && api[key] !== "") {
          payload[key] = api[key];
        }
      });

      payload = JSON.stringify(payload);
    }

    const res = http.request(api.method, api.url, payload, { headers });

    apiMetrics[api.api_name].latency.add(res.timings.duration);
    apiMetrics[api.api_name].errors.add(res.status !== 200);
    apiMetrics[api.api_name].requests.add(1);

    console.log(`${api.api_name} → ${res.status} | ${res.timings.duration} ms`);

    check(res, {
      'status is 200': (r) => r.status === 200,
    });

    sleep(0.2);
  }
}
