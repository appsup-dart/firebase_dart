window.BENCHMARK_DATA = {
  "lastUpdate": 1779741850564,
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
      },
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
          "id": "d78d26e58a9786a5c92ae98a15b4cc32ab30e455",
          "message": "perf: increase speed of IncompleteData.applyOperation",
          "timestamp": "2026-05-25T22:42:13+02:00",
          "tree_id": "49afe01a4a6a6238b329115806c517e9189fa932",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/d78d26e58a9786a5c92ae98a15b4cc32ab30e455"
        },
        "date": 1779741850099,
        "tool": "benchmarkjs",
        "benches": [
          {
            "name": "IncompleteData merge applyOperation (complete root merge)",
            "value": 1013,
            "range": "±1.19%",
            "unit": "ops/sec",
            "extra": "2026 samples"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack)",
            "value": 380,
            "range": "±4.30%",
            "unit": "ops/sec",
            "extra": "761 samples"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge)",
            "value": 17332,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "34665 samples"
          },
          {
            "name": "synctree merge write path userMerge only",
            "value": 877,
            "range": "±1.33%",
            "unit": "ops/sec",
            "extra": "1754 samples"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge)",
            "value": 656,
            "range": "±1.83%",
            "unit": "ops/sec",
            "extra": "1312 samples"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge)",
            "value": 15680,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "31360 samples"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge",
            "value": 933,
            "range": "±0.93%",
            "unit": "ops/sec",
            "extra": "1866 samples"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots",
            "value": 557,
            "range": "±2.63%",
            "unit": "ops/sec",
            "extra": "1114 samples"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots",
            "value": 214,
            "range": "±1.10%",
            "unit": "ops/sec",
            "extra": "429 samples"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots",
            "value": 294,
            "range": "±1.03%",
            "unit": "ops/sec",
            "extra": "589 samples"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack",
            "value": 2565,
            "range": "±0.73%",
            "unit": "ops/sec",
            "extra": "5131 samples"
          }
        ]
      }
    ]
  }
}