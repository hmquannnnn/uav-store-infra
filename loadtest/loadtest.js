// k6 stress test cho UAV Store — chứng minh load balancing + auto scaling.
//
// Target: GET /api/products?page=1&limit=20  (đi qua api-gateway → product-service)
// Đây là endpoint read-heavy nhất (browse storefront), không sửa DB, không gọi gRPC,
// nên CPU bound rõ ràng ⇒ kích hoạt HPA dựa trên CPU utilization nhanh và sạch.
//
// Stages (tổng ~3 phút):
//   0:00 → 0:30   ramp-up   0  → 20 VUs   (warm-up, baseline RPS)
//   0:30 → 1:30   ramp-up  20  → 80 VUs   (kích hoạt scale-up: CPU vượt 60%)
//   1:30 → 2:30   sustain  80  VUs        (quan sát LB đều giữa pods mới)
//   2:30 → 3:00   ramp-down 80 → 0 VUs    (kích hoạt scale-down sau cool-down 60s)
//
// Thresholds: pipeline coi là pass nếu
//   - p95 latency < 2000 ms (api gateway + product-svc chuyển 5x replicas)
//   - error rate < 5%      (cho phép 1 số request bị reject trong lúc rolling scale)

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m',  target: 80 },
    { duration: '1m',  target: 80 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000'],
    http_req_failed:   ['rate<0.05'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

const BASE_URL = __ENV.BASE_URL || 'http://api.uav-store.io.vn';

export default function () {
  const res = http.get(`${BASE_URL}/api/products?page=1&limit=20`);
  check(res, {
    'status is 200': (r) => r.status === 200,
    'has data array': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body?.data?.items ?? body?.data);
      } catch (_) {
        return false;
      }
    },
  });
  // 500ms think time để mỗi VU ~ 2 req/s.
  // Với 80 VUs target ⇒ ~160 RPS sustained.
  sleep(0.5);
}
