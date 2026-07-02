import http from "k6/http";
import { check } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 25 },
    { duration: "2m", target: 200 },
    { duration: "3m", target: 200 },
    { duration: "2m", target: 25 },
    { duration: "1m", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<1200"],
    http_req_failed: ["rate<0.03"],
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
}
