window.BENCHMARK_DATA = {
  "lastUpdate": 1779737016872,
  "repoUrl": "https://github.com/appsup-dart/firebase_dart",
  "entries": {
    "Benchmark": [
      {
        "commit": {
          "author": {
            "email": "rik.bellens@appsup.be",
            "name": "rikbellens",
            "username": "rbellens"
          },
          "committer": {
            "email": "rik.bellens@appsup.be",
            "name": "rikbellens",
            "username": "rbellens"
          },
          "distinct": true,
          "id": "9a7a9f3b8e500fda8d3b01d6135202343d052cd6",
          "message": "test: create benchmark tests",
          "timestamp": "2026-05-25T21:21:32+02:00",
          "tree_id": "89aac0f5d1516078bd9a968f0bbc8fc5194ca46e",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/9a7a9f3b8e500fda8d3b01d6135202343d052cd6"
        },
        "date": 1779737016316,
        "tool": "benchmarkjs",
        "benches": [
          {
            "name": "IncompleteData merge applyOperation (complete root merge)",
            "value": 1084,
            "range": "±1.26%",
            "unit": "ops/sec",
            "extra": "2169 samples"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack)",
            "value": 132,
            "range": "±5.09%",
            "unit": "ops/sec",
            "extra": "264 samples"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge)",
            "value": 1176,
            "range": "±0.70%",
            "unit": "ops/sec",
            "extra": "2354 samples"
          },
          {
            "name": "synctree merge write path userMerge only",
            "value": 382,
            "range": "±1.36%",
            "unit": "ops/sec",
            "extra": "764 samples"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge)",
            "value": 692,
            "range": "±0.87%",
            "unit": "ops/sec",
            "extra": "1385 samples"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge)",
            "value": 534,
            "range": "±1.93%",
            "unit": "ops/sec",
            "extra": "1069 samples"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge",
            "value": 244,
            "range": "±2.20%",
            "unit": "ops/sec",
            "extra": "489 samples"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots",
            "value": 598,
            "range": "±2.42%",
            "unit": "ops/sec",
            "extra": "1196 samples"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots",
            "value": 222,
            "range": "±1.50%",
            "unit": "ops/sec",
            "extra": "444 samples"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots",
            "value": 285,
            "range": "±1.86%",
            "unit": "ops/sec",
            "extra": "571 samples"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack",
            "value": 1030,
            "range": "±1.06%",
            "unit": "ops/sec",
            "extra": "2061 samples"
          }
        ]
      }
    ]
  }
}