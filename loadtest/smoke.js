import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 5,
  duration: "2m",
  thresholds: {
    http_req_duration: ["p(95)<800"],
    http_req_failed: ["rate<0.02"],
  },
};

const baseUrl = __ENV.BASE_URL;
const healthPath = __ENV.HEALTH_PATH || "/";

if (!baseUrl) {
  throw new Error("BASE_URL is required. Example: BASE_URL=https://app.example.com");
}

export default function () {
  const res = http.get(`${baseUrl}${healthPath}`);
  check(res, {
    "status is 2xx/3xx": (r) => r.status >= 200 && r.status < 400,
  });
  sleep(1);
}
