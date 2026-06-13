window.BENCHMARK_DATA = {
  "lastUpdate": 1781356912154,
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
    ],
    "Dart Benchmarks": [
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
          "id": "71ba6deed6604da730bf00f5b8f84a85fa7b131d",
          "message": "chore: upgrade to benchmark_test v0.1.1+2",
          "timestamp": "2026-05-28T19:40:57+02:00",
          "tree_id": "38838da601455cd78955189e1a826dde9e96740c",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/71ba6deed6604da730bf00f5b8f84a85fa7b131d"
        },
        "date": 1779993078926,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 673.8402998489357,
            "range": "±2.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1348\nmean latency: 1484 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 244.66309891279707,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 490\nmean latency: 4087 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 332.5306330115042,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 666\nmean latency: 3007 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 2507.1840948040544,
            "range": "±0.76%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5015\nmean latency: 399 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 23145.34955522789,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 46291\nmean latency: 43 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 637.434344262541,
            "range": "±0.78%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1275\nmean latency: 1569 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 11269.27461450771,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 22539\nmean latency: 89 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 357.8382571077873,
            "range": "±0.88%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 716\nmean latency: 2795 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 884.8606344500741,
            "range": "±0.49%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1770\nmean latency: 1130 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 782.8121250899784,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1566\nmean latency: 1277 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 2227.1469972009436,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4455\nmean latency: 449 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 771.957928292908,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1544\nmean latency: 1295 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 271.07874363239523,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 543\nmean latency: 3689 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 375.72496932245593,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 752\nmean latency: 2662 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 2506.337088089274,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5013\nmean latency: 399 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 19326.442020673938,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 38653\nmean latency: 52 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 919.8086797946028,
            "range": "±0.11%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1840\nmean latency: 1087 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 13927.749300512593,
            "range": "±0.11%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 27856\nmean latency: 72 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 344.34005404489614,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 689\nmean latency: 2904 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 777.2081583365447,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1555\nmean latency: 1287 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 766.2819927730561,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1533\nmean latency: 1305 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 2548.494903010194,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5097\nmean latency: 392 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 103.58565737051792,
            "range": "±2.82%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 208\nmean latency: 9654 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 48.65938430983118,
            "range": "±1.58%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 98\nmean latency: 20551 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 80.259222333001,
            "range": "±1.76%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 161\nmean latency: 12460 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 148.5,
            "range": "±1.23%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 297\nmean latency: 6734 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2589,
            "range": "±3.43%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 5178\nmean latency: 386 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 109.5617529880478,
            "range": "±0.59%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 220\nmean latency: 9127 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1862.0000000000002,
            "range": "±2.99%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3724\nmean latency: 537 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 61.660865241173546,
            "range": "±1.80%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 124\nmean latency: 16218 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 145,
            "range": "±0.83%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 290\nmean latency: 6897 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 140.21956087824353,
            "range": "±0.57%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 281\nmean latency: 7132 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 412.7936031984008,
            "range": "±1.40%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 826\nmean latency: 2423 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 237.36754890770948,
            "range": "±1.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 475\nmean latency: 4213 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 94.16641547318623,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 189\nmean latency: 10619 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 140.83114345899267,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 282\nmean latency: 7101 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 461.12487491425725,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 923\nmean latency: 2169 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7805.5667910430975,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 15612\nmean latency: 128 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 248.35272683298805,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 497\nmean latency: 4027 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 5143.825109946262,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 10288\nmean latency: 194 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 168.127429615971,
            "range": "±1.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 337\nmean latency: 5948 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 396.52496309421315,
            "range": "±0.63%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 794\nmean latency: 2522 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 321.8070766575438,
            "range": "±1.73%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 644\nmean latency: 3107 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 1040.9182879143987,
            "range": "±0.89%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2082\nmean latency: 961 microseconds"
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
          "id": "d68e2e61b43ca7c532f91f958c7049419732e263",
          "message": "perf: avoid creating new IncompleteData instances on no-ops",
          "timestamp": "2026-05-29T11:25:06+02:00",
          "tree_id": "3f5ef015535ad83d075235d583d4c5d4a30535d9",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/d68e2e61b43ca7c532f91f958c7049419732e263"
        },
        "date": 1780047001357,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1009.1538602259425,
            "range": "±1.98%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2019\nmean latency: 991 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 337.3711242305439,
            "range": "±0.80%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 675\nmean latency: 2964 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 402.2228684436423,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 805\nmean latency: 2486 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1889.4036404143387,
            "range": "±0.78%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3779\nmean latency: 529 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 18598.10014084697,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 37197\nmean latency: 54 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 589.9180013978057,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1180\nmean latency: 1695 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 10674.5,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 21349\nmean latency: 94 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 449.366987371738,
            "range": "±0.60%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 899\nmean latency: 2225 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 1067.1297059920207,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2135\nmean latency: 937 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 1029.9459278387885,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2060\nmean latency: 971 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 3595.304055928952,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7191\nmean latency: 278 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1136.2176499139964,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2273\nmean latency: 880 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 356.653689267721,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 714\nmean latency: 2804 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 424.97282121528247,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 851\nmean latency: 2353 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1819.4708884657846,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3639\nmean latency: 550 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 16799.27320981167,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 33599\nmean latency: 60 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 905.07280563574,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1811\nmean latency: 1105 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 13075.48038677942,
            "range": "±0.10%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 26151\nmean latency: 76 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 393.61052238809697,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 788\nmean latency: 2541 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 858.2266548104428,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1717\nmean latency: 1165 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 833.8561598124323,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1668\nmean latency: 1199 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 4270.245920367738,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8541\nmean latency: 234 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 154.19161676646706,
            "range": "±2.92%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 309\nmean latency: 6485 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 73.5,
            "range": "±1.05%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 147\nmean latency: 13605 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 95.56993529118965,
            "range": "±1.21%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 192\nmean latency: 10464 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 114.00000000000001,
            "range": "±2.28%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 228\nmean latency: 8772 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2251,
            "range": "±3.27%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4502\nmean latency: 444 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 107.8921078921079,
            "range": "±0.72%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 216\nmean latency: 9269 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1829.5,
            "range": "±2.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3659\nmean latency: 547 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 68.75934230194319,
            "range": "±1.49%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 138\nmean latency: 14543 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 156.60847880299252,
            "range": "±0.87%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 314\nmean latency: 6385 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 151,
            "range": "±0.85%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 302\nmean latency: 6623 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 560.2198900549726,
            "range": "±1.44%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1121\nmean latency: 1785 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 406.7419222503322,
            "range": "±1.60%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 814\nmean latency: 2459 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 144.35694227021023,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 289\nmean latency: 6927 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 187.39580793079048,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 375\nmean latency: 5336 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 422.8129052894094,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 846\nmean latency: 2365 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7336.842257891454,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14674\nmean latency: 136 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 283.5628878084433,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 568\nmean latency: 3527 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 5972.60580801667,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 11946\nmean latency: 167 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 210.9971936874428,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 423\nmean latency: 4739 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 470.91735400437227,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 942\nmean latency: 2124 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 480.0521113800824,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 961\nmean latency: 2083 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 1647.3813885400252,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3295\nmean latency: 607 microseconds"
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
          "id": "5bb274c8e0c7bf73d6a21af13b464887cc7d61aa",
          "message": "perf: use TreeMap iso SortedMap/HashMap for fast cloning",
          "timestamp": "2026-05-29T14:30:07+02:00",
          "tree_id": "86538fbfbc2c1d883e22fb468e650d97cbd98720",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/5bb274c8e0c7bf73d6a21af13b464887cc7d61aa"
        },
        "date": 1780058257915,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1067.7357354054873,
            "range": "±1.48%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2136\nmean latency: 937 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 346.3008769957275,
            "range": "±0.83%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 693\nmean latency: 2888 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 403.9650570225676,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 808\nmean latency: 2475 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1965.9292265478443,
            "range": "±0.59%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3932\nmean latency: 509 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 19415.936937828803,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 38833\nmean latency: 52 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 5123.087591448888,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10247\nmean latency: 195 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 8577.238394228976,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 17155\nmean latency: 117 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 375.30615437126727,
            "range": "±0.91%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 751\nmean latency: 2664 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 948.9136488579538,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1898\nmean latency: 1054 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 908.2193602176927,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1817\nmean latency: 1101 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 2804.6297888678696,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5610\nmean latency: 357 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1125.9684728827592,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2252\nmean latency: 888 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 370.28190395856836,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 741\nmean latency: 2701 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 433.7809406249844,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 868\nmean latency: 2305 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1858.4080088035644,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3717\nmean latency: 538 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 16003.759943600846,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 32008\nmean latency: 62 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 4758.262086895656,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9517\nmean latency: 210 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 7425.444309167681,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 14851\nmean latency: 135 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 349.9648285347323,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 700\nmean latency: 2857 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 820.3076378589221,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1641\nmean latency: 1219 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 780.3357393268717,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1561\nmean latency: 1281 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 2536.4264436331346,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5073\nmean latency: 394 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 170.5,
            "range": "±2.82%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 341\nmean latency: 5865 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 75.65953210552513,
            "range": "±1.17%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 152\nmean latency: 13217 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 99.15296462381664,
            "range": "±1.53%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 199\nmean latency: 10085 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 120.57797708021924,
            "range": "±1.05%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 242\nmean latency: 8293 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2475,
            "range": "±3.39%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4950\nmean latency: 404 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 675.5,
            "range": "±1.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1351\nmean latency: 1480 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1162,
            "range": "±1.68%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2324\nmean latency: 861 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 58.560794044665016,
            "range": "±1.53%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 118\nmean latency: 17076 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 143.928035982009,
            "range": "±0.64%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 288\nmean latency: 6948 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 137.29405891163253,
            "range": "±0.75%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 275\nmean latency: 7284 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 379.6203796203796,
            "range": "±1.33%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 760\nmean latency: 2634 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 369.3891832450265,
            "range": "±1.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 739\nmean latency: 2707 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 127.67156489929656,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 256\nmean latency: 7833 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 162.58694785896432,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 326\nmean latency: 6151 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 400.16266287519625,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 801\nmean latency: 2499 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7472.066620136032,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14945\nmean latency: 134 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 1753.3553481837746,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3507\nmean latency: 570 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 3547.1718866004894,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 7095\nmean latency: 282 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 167.31227562674678,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 335\nmean latency: 5977 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 396.6836447932773,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 794\nmean latency: 2521 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 384.21894384257916,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 769\nmean latency: 2603 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 1071.6088627650909,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2144\nmean latency: 933 microseconds"
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
          "id": "618727d61d3d3659dfc4f56c954880efb14eb083",
          "message": "perf: speed up operationForChild for Merge operations",
          "timestamp": "2026-05-29T14:39:38+02:00",
          "tree_id": "9c1602a8211c019564197762bbeda98aeb7eabb0",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/618727d61d3d3659dfc4f56c954880efb14eb083"
        },
        "date": 1780058605018,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 2035.347348948829,
            "range": "±1.00%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4071\nmean latency: 491 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 667.4355924653271,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1335\nmean latency: 1498 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 781.4308433703618,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1563\nmean latency: 1280 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 3678.446662523393,
            "range": "±0.49%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7357\nmean latency: 272 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 34491,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 68982\nmean latency: 29 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 9847.278436235185,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 19695\nmean latency: 102 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 15947.736862341771,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 31896\nmean latency: 63 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 1301.88999029582,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2604\nmean latency: 768 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 3741.112794825736,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7483\nmean latency: 267 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 3175.403150203919,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6351\nmean latency: 315 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 5126.364151349989,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10253\nmean latency: 195 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 2104.3642685046816,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4209\nmean latency: 475 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 697.4344411625307,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1395\nmean latency: 1434 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 811.5491844280502,
            "range": "±0.95%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1624\nmean latency: 1232 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 3455.70108185642,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 6912\nmean latency: 289 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 30222.773329200034,
            "range": "±0.11%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 60446\nmean latency: 33 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 9005.229843104707,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 18011\nmean latency: 111 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 14239.935920288359,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 28480\nmean latency: 70 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 1232.3200812681348,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2465\nmean latency: 811 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 3538.2647053970913,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7077\nmean latency: 283 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 3041.305356457187,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 6083\nmean latency: 329 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 4869.492695760956,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9739\nmean latency: 205 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 308.5,
            "range": "±1.64%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 617\nmean latency: 3241 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 139.22155688622755,
            "range": "±1.00%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 279\nmean latency: 7183 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 178.64271457085826,
            "range": "±1.01%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 358\nmean latency: 5598 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 235.88205897051475,
            "range": "±1.02%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 472\nmean latency: 4239 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 4614,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9228\nmean latency: 217 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 1266,
            "range": "±2.02%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2532\nmean latency: 790 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 2155.5,
            "range": "±3.21%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4311\nmean latency: 464 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 174.5,
            "range": "±1.19%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 349\nmean latency: 5731 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 496.5,
            "range": "±0.80%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 993\nmean latency: 2014 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 426,
            "range": "±1.70%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 852\nmean latency: 2347 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 668,
            "range": "±1.86%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1336\nmean latency: 1497 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 708.6130972489021,
            "range": "±1.04%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1418\nmean latency: 1411 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 247.40858252875563,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 495\nmean latency: 4042 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 305.33145703571626,
            "range": "±0.56%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 611\nmean latency: 3275 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 728.1723224548954,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1457\nmean latency: 1373 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 13642.049812356192,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 27285\nmean latency: 73 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 3420.1528544852695,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 6841\nmean latency: 292 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 6677.483306291735,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 13355\nmean latency: 150 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 531.3913304729183,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1063\nmean latency: 1882 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 1441.291605176056,
            "range": "±0.91%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2884\nmean latency: 694 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 1323.462281324982,
            "range": "±0.61%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2647\nmean latency: 756 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 2000.6188821029593,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4002\nmean latency: 500 microseconds"
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
          "id": "3d86f2d11afb27a5a23dc6c22dd4fb1cd866919b",
          "message": "perf: avoid double lookup (operator[] after containsKey) in ModifiableTreeNode.subtree",
          "timestamp": "2026-05-29T14:59:32+02:00",
          "tree_id": "8d135bcb393fc95b225ff2af3efcdb345429f916",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/3d86f2d11afb27a5a23dc6c22dd4fb1cd866919b"
        },
        "date": 1780059829801,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 993.1300590530028,
            "range": "±1.90%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1987\nmean latency: 1007 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 328.3709502165649,
            "range": "±0.57%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 657\nmean latency: 3045 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 389.8294496157931,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 780\nmean latency: 2565 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1859.8372642393792,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3720\nmean latency: 538 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 17525.3685597358,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 35051\nmean latency: 57 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 4679.906401871963,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9360\nmean latency: 214 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 7829.722044867407,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 15660\nmean latency: 128 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 749.1366687156728,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1499\nmean latency: 1335 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 2129.157205689884,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4259\nmean latency: 470 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 1831.444140953701,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3663\nmean latency: 546 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 3056.2600835834382,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6113\nmean latency: 327 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1113.715445703623,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2228\nmean latency: 898 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 364.9396024957869,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 730\nmean latency: 2740 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 427.55747801025933,
            "range": "±0.55%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 856\nmean latency: 2339 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1811.9998880309035,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3625\nmean latency: 552 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 16866.789165135437,
            "range": "±0.10%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 33734\nmean latency: 59 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 4593.219813591371,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9187\nmean latency: 218 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 7618.939048487612,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 15238\nmean latency: 131 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 768.967703356459,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1538\nmean latency: 1300 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 2155.8264559702943,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4312\nmean latency: 464 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 1837.3107569920298,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3675\nmean latency: 544 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 3177.54243388952,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 6356\nmean latency: 315 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 151.69660678642714,
            "range": "±2.81%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 304\nmean latency: 6592 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 71.46426786606696,
            "range": "±1.09%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 143\nmean latency: 13993 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 93.76558603491272,
            "range": "±0.94%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 188\nmean latency: 10665 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 108.61983059292477,
            "range": "±1.78%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 218\nmean latency: 9206 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2205.5,
            "range": "±3.24%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4411\nmean latency: 453 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 653.5,
            "range": "±1.80%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1307\nmean latency: 1530 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1079,
            "range": "±1.22%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2158\nmean latency: 927 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 100.54753608760576,
            "range": "±1.85%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 202\nmean latency: 9946 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 284.3578210894553,
            "range": "±1.31%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 569\nmean latency: 3517 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 248.87556221889056,
            "range": "±0.80%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 498\nmean latency: 4018 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 431.784107946027,
            "range": "±1.40%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 864\nmean latency: 2316 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 401.5893748642014,
            "range": "±1.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 804\nmean latency: 2490 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 141.99435809083852,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 285\nmean latency: 7043 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 182.84896675346164,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 366\nmean latency: 5469 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 430.5281411572916,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 862\nmean latency: 2323 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7673.750603105399,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 15348\nmean latency: 130 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 1903.5992923489605,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3808\nmean latency: 525 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 3671.05213163994,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 7343\nmean latency: 272 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 348.79002840290144,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 698\nmean latency: 2867 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 953.2269004930087,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1907\nmean latency: 1049 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 874.1389806010118,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1749\nmean latency: 1144 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 1390.292151323377,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2781\nmean latency: 719 microseconds"
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
          "id": "b0cf96c32f155e27939cbed90842f62a381db283",
          "message": "fix: several tests failing after work on performance",
          "timestamp": "2026-06-02T11:35:38+02:00",
          "tree_id": "75c77bb94747c93f76daf95042c7e02794644d5d",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/b0cf96c32f155e27939cbed90842f62a381db283"
        },
        "date": 1780393203678,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1021.9100719136716,
            "range": "±2.31%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2044\nmean latency: 979 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 349.48829214221325,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 699\nmean latency: 2861 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 394.45089086408746,
            "range": "±1.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 789\nmean latency: 2535 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1862.9972055041915,
            "range": "±0.89%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3726\nmean latency: 537 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 18634.757748149274,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 37270\nmean latency: 54 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 5078.141990989635,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10157\nmean latency: 197 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 8243.542483392172,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 16488\nmean latency: 121 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 749.243758634547,
            "range": "±1.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1499\nmean latency: 1335 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 2135.083658686556,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4271\nmean latency: 468 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 1882.3174152107244,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3765\nmean latency: 531 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 3077.6045278181755,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6156\nmean latency: 325 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1167.2385385673608,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2335\nmean latency: 857 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 376.4198225777909,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 753\nmean latency: 2657 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 446.51084736670975,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 894\nmean latency: 2240 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1926.4249621487986,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3854\nmean latency: 519 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 17842.83941444527,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 35686\nmean latency: 56 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 5175.544552079417,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10352\nmean latency: 193 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 8261.971083101209,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 16524\nmean latency: 121 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 813.9983720032559,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1628\nmean latency: 1229 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 2194.7399233190868,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4390\nmean latency: 456 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 1911.5469633696814,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3824\nmean latency: 523 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 3358.4865660537357,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 6717\nmean latency: 298 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 156.60847880299252,
            "range": "±3.19%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 314\nmean latency: 6385 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 74.42557442557442,
            "range": "±1.74%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 149\nmean latency: 13436 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 98.9010989010989,
            "range": "±0.83%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 198\nmean latency: 10111 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 119.5814648729447,
            "range": "±1.34%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 240\nmean latency: 8363 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2361.5,
            "range": "±3.33%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4723\nmean latency: 423 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 671,
            "range": "±1.84%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1342\nmean latency: 1490 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1097,
            "range": "±1.69%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2194\nmean latency: 912 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 105.18444666001993,
            "range": "±1.54%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 211\nmean latency: 9507 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 290.5,
            "range": "±1.23%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 581\nmean latency: 3442 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 258,
            "range": "±1.04%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 516\nmean latency: 3876 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 440.279860069965,
            "range": "±1.43%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 881\nmean latency: 2271 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 370.6314070656732,
            "range": "±1.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 742\nmean latency: 2698 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 126.3391702362892,
            "range": "±0.56%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 253\nmean latency: 7915 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 162.87434244480383,
            "range": "±0.57%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 326\nmean latency: 6140 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 387.17032446871485,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 775\nmean latency: 2583 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7392.696899427124,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14786\nmean latency: 135 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 1745.9127043647818,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3492\nmean latency: 573 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 3473.5866431894606,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 6948\nmean latency: 288 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 311.059073762941,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 623\nmean latency: 3215 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 830.0658755470889,
            "range": "±0.56%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1661\nmean latency: 1205 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 786.4378714081587,
            "range": "±0.70%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1573\nmean latency: 1272 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 1214.0010455702707,
            "range": "±0.91%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2429\nmean latency: 824 microseconds"
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
          "id": "3b455cc07fa90ad682b3a1771a4c8a49218aa384",
          "message": "perf: use TreeMap for children of WriteTree and HashMap for other ModifiableTreeNodes",
          "timestamp": "2026-06-02T14:47:04+02:00",
          "tree_id": "d07280881381fa559a034ad28396f796f4699f74",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/3b455cc07fa90ad682b3a1771a4c8a49218aa384"
        },
        "date": 1780404683198,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1048.7808048117943,
            "range": "±1.90%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2098\nmean latency: 953 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 346.8631624824007,
            "range": "±0.48%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 694\nmean latency: 2883 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 406.44167561954856,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 813\nmean latency: 2460 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1866.6817307649046,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3734\nmean latency: 536 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 18922.85807856441,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 37846\nmean latency: 53 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 4821.196264635328,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9643\nmean latency: 207 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 7917.750590856388,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 15836\nmean latency: 126 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 988.7869164195116,
            "range": "±0.58%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1978\nmean latency: 1011 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 2625.162666597342,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5251\nmean latency: 381 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 2304.4850208473645,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4609\nmean latency: 434 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 4666.388006687839,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9333\nmean latency: 214 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1195.3918170405577,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2391\nmean latency: 837 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 390.2623302408833,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 781\nmean latency: 2562 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 455.8614181288888,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 912\nmean latency: 2194 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1852.7600675712495,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3706\nmean latency: 540 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 16378.885347802565,
            "range": "±0.08%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 32758\nmean latency: 61 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 5085.626206473825,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10172\nmean latency: 197 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 7766.693215617984,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 15534\nmean latency: 129 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 1118.807005791501,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2238\nmean latency: 894 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 2883.1828498865125,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5767\nmean latency: 347 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 2449.4191691674173,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4899\nmean latency: 408 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 5554.794472604513,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 11110\nmean latency: 180 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 153.84615384615384,
            "range": "±2.80%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 308\nmean latency: 6500 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 75.46226886556721,
            "range": "±1.28%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 151\nmean latency: 13252 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 98.95052473763118,
            "range": "±0.74%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 198\nmean latency: 10106 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 112.94352823588206,
            "range": "±1.91%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 226\nmean latency: 8854 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2208,
            "range": "±3.25%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4416\nmean latency: 453 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 659.5,
            "range": "±1.86%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1319\nmean latency: 1516 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1062.5,
            "range": "±1.10%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2125\nmean latency: 941 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 142.21556886227546,
            "range": "±1.68%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 285\nmean latency: 7032 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 366.6333666333666,
            "range": "±1.48%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 734\nmean latency: 2728 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 321.3393303348326,
            "range": "±0.78%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 643\nmean latency: 3112 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 727.5000000000001,
            "range": "±1.82%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1455\nmean latency: 1375 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 417.2928141177905,
            "range": "±1.51%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 835\nmean latency: 2396 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 149.2887564096803,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 299\nmean latency: 6698 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 191.74497917769366,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 384\nmean latency: 5215 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 425.6086528437102,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 852\nmean latency: 2350 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7551.420710082545,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 15103\nmean latency: 132 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 2091.264732717569,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4183\nmean latency: 478 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 3747.419430482245,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 7495\nmean latency: 267 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 480.76322411212476,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 962\nmean latency: 2080 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 1227.486497648526,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2455\nmean latency: 815 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 1144.9891226033353,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2290\nmean latency: 873 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 2160.971642433425,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4323\nmean latency: 463 microseconds"
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
          "id": "618727d61d3d3659dfc4f56c954880efb14eb083",
          "message": "perf: speed up operationForChild for Merge operations",
          "timestamp": "2026-05-29T14:39:38+02:00",
          "tree_id": "9c1602a8211c019564197762bbeda98aeb7eabb0",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/618727d61d3d3659dfc4f56c954880efb14eb083"
        },
        "date": 1781349796413,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1060.817539383226,
            "range": "±1.48%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2122\nmean latency: 943 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 346.72175579097774,
            "range": "±0.58%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 694\nmean latency: 2884 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 404.314217617005,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 809\nmean latency: 2473 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1972.2169868623853,
            "range": "±0.57%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3945\nmean latency: 507 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 19418.131055509944,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 38837\nmean latency: 51 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 5104.178436758484,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10209\nmean latency: 196 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 8532.995733502134,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 17066\nmean latency: 117 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 652.8547398203899,
            "range": "±0.87%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1306\nmean latency: 1532 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 1945.4727768774665,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3892\nmean latency: 514 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 1677.0304314791858,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3355\nmean latency: 596 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 2689.2606558016337,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5379\nmean latency: 372 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1136.1795973535463,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2273\nmean latency: 880 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 361.9444415282254,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 724\nmean latency: 2763 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 432.4124364816125,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 865\nmean latency: 2313 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1921.41065440457,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3843\nmean latency: 520 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 17797.117361976718,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 35595\nmean latency: 56 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 5048.028009381123,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10097\nmean latency: 198 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 8124.589708219734,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 16250\nmean latency: 123 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 644.9774257900974,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1290\nmean latency: 1550 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 1822.3205014306088,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3645\nmean latency: 549 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 1485.3225039607767,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2971\nmean latency: 673 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 2691.101716945892,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5383\nmean latency: 372 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 169,
            "range": "±2.53%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 338\nmean latency: 5917 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 75.73492775286496,
            "range": "±1.27%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 152\nmean latency: 13204 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 97.80439121756487,
            "range": "±0.69%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 196\nmean latency: 10224 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 120.19950124688279,
            "range": "±2.03%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 241\nmean latency: 8320 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2411,
            "range": "±3.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4822\nmean latency: 415 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 676,
            "range": "±1.84%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1352\nmean latency: 1479 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1119,
            "range": "±1.56%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2238\nmean latency: 894 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 90.22931206380858,
            "range": "±2.09%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 181\nmean latency: 11083 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 251,
            "range": "±1.50%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 502\nmean latency: 3984 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 229.1562656015976,
            "range": "±1.02%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 459\nmean latency: 4364 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 372,
            "range": "±1.29%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 744\nmean latency: 2688 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 369.0020317581424,
            "range": "±1.14%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 739\nmean latency: 2710 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 125.70791765333249,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 252\nmean latency: 7955 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 159.41120795716785,
            "range": "±0.48%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 319\nmean latency: 6273 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 392.66799920667074,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 786\nmean latency: 2547 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7385.774733870617,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14772\nmean latency: 135 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 1754.77977513822,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3510\nmean latency: 570 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 3540.8813804737542,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 7082\nmean latency: 282 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 273.59753802157024,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 548\nmean latency: 3655 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 767.0754237529528,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1535\nmean latency: 1304 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 695.9913001087486,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1392\nmean latency: 1437 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 1055.7434543405952,
            "range": "±0.56%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2112\nmean latency: 947 microseconds"
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
          "id": "3b455cc07fa90ad682b3a1771a4c8a49218aa384",
          "message": "perf: use TreeMap for children of WriteTree and HashMap for other ModifiableTreeNodes",
          "timestamp": "2026-06-02T14:47:04+02:00",
          "tree_id": "d07280881381fa559a034ad28396f796f4699f74",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/3b455cc07fa90ad682b3a1771a4c8a49218aa384"
        },
        "date": 1781356537194,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1034.749590599075,
            "range": "±1.88%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2070\nmean latency: 966 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 340.8088062596883,
            "range": "±0.73%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 682\nmean latency: 2934 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 405.824278087588,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 812\nmean latency: 2464 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1868.205757593179,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3737\nmean latency: 535 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 18952.139909341724,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 37905\nmean latency: 53 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 4723.9362268609375,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9448\nmean latency: 212 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 7858.350691336865,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 15717\nmean latency: 127 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 975.9229020907349,
            "range": "±0.75%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1952\nmean latency: 1025 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 2689.709511372772,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5380\nmean latency: 372 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 2290.2870033086924,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4581\nmean latency: 437 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 4610.354773824624,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9221\nmean latency: 217 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1176.6799430554888,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2354\nmean latency: 850 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 385.811145444305,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 772\nmean latency: 2592 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 453.0474056417639,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 907\nmean latency: 2207 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1871.918571542138,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3744\nmean latency: 534 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 17229.43108227567,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 34459\nmean latency: 58 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 5053.262496662656,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10107\nmean latency: 198 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 7687.692492300308,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 15376\nmean latency: 130 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 1114.8951998512139,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2230\nmean latency: 897 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 2923.8508836049364,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5848\nmean latency: 342 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 2457.0749260377956,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4915\nmean latency: 407 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 5235.863867539444,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10472\nmean latency: 191 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 149.77533699450822,
            "range": "±2.76%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 300\nmean latency: 6677 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 72.92707292707293,
            "range": "±1.29%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 146\nmean latency: 13712 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 95.71286141575274,
            "range": "±0.93%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 192\nmean latency: 10448 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 111.83225162256615,
            "range": "±1.55%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 224\nmean latency: 8942 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2233.5,
            "range": "±3.26%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4467\nmean latency: 448 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 654.5,
            "range": "±1.85%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1309\nmean latency: 1528 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1048,
            "range": "±1.02%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2096\nmean latency: 954 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 140,
            "range": "±1.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 280\nmean latency: 7143 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 369.5,
            "range": "±1.30%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 739\nmean latency: 2706 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 313.03045431852223,
            "range": "±0.97%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 627\nmean latency: 3195 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 693.6531734132933,
            "range": "±1.82%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1388\nmean latency: 1442 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 404.9307568405802,
            "range": "±1.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 810\nmean latency: 2470 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 145.65857629715947,
            "range": "±0.58%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 292\nmean latency: 6865 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 187.54857059058847,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 376\nmean latency: 5332 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 420.7847685908658,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 842\nmean latency: 2377 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7512.473706342028,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 15025\nmean latency: 133 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 2047.3884173312556,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4095\nmean latency: 488 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 3627.322261209201,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 7255\nmean latency: 276 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 472.1763231304941,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 945\nmean latency: 2118 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 1203.9458224379903,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2408\nmean latency: 831 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 1113.709878576631,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2228\nmean latency: 898 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 2083.7447412691945,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4168\nmean latency: 480 microseconds"
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
          "id": "71ba6deed6604da730bf00f5b8f84a85fa7b131d",
          "message": "chore: upgrade to benchmark_test v0.1.1+2",
          "timestamp": "2026-05-28T19:40:57+02:00",
          "tree_id": "38838da601455cd78955189e1a826dde9e96740c",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/71ba6deed6604da730bf00f5b8f84a85fa7b131d"
        },
        "date": 1781356911839,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 672.8775362883955,
            "range": "±2.12%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1346\nmean latency: 1486 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 238.19499131362292,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 477\nmean latency: 4198 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 319.4059349521566,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 639\nmean latency: 3131 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1955.214538677353,
            "range": "±0.91%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3911\nmean latency: 511 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 23184.978337987395,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 46371\nmean latency: 43 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 651.0732215033046,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1303\nmean latency: 1536 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 11096.211498501038,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 22193\nmean latency: 90 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 355.2309125837178,
            "range": "±0.80%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 711\nmean latency: 2815 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [jit]",
            "value": 884.6156345068068,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1770\nmean latency: 1130 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 818.2198273945792,
            "range": "±0.59%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1638\nmean latency: 1222 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [jit]",
            "value": 2238.85447445916,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4478\nmean latency: 447 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 746.7266980285216,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1494\nmean latency: 1339 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 266.36295625900476,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 533\nmean latency: 3754 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 372.3540372174108,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 745\nmean latency: 2686 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 2052.4866588367177,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4105\nmean latency: 487 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 19157.471263793104,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 38315\nmean latency: 52 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 915.3896955416872,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1831\nmean latency: 1092 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 13641.48635851364,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 27283\nmean latency: 73 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 343.23467959267487,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 687\nmean latency: 2913 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [aot]",
            "value": 789.1050529210131,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1579\nmean latency: 1267 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 761.1376984555352,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1523\nmean latency: 1314 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [aot]",
            "value": 2477.6878113357716,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4956\nmean latency: 404 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 100,
            "range": "±2.63%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 200\nmean latency: 10000 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 44.820717131474105,
            "range": "±3.78%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 90\nmean latency: 22311 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 77.7666999002991,
            "range": "±1.34%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 156\nmean latency: 12859 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 128.43578210894552,
            "range": "±1.08%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 257\nmean latency: 7786 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2639.5,
            "range": "±3.46%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 5279\nmean latency: 379 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 107.51617720258837,
            "range": "±0.81%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 216\nmean latency: 9301 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1863.5,
            "range": "±2.99%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3727\nmean latency: 537 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 57.24240915878546,
            "range": "±1.85%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 115\nmean latency: 17470 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [js]",
            "value": 137.86213786213787,
            "range": "±0.77%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 276\nmean latency: 7254 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 132.16957605985036,
            "range": "±0.85%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 265\nmean latency: 7566 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [js]",
            "value": 367.5,
            "range": "±1.30%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 735\nmean latency: 2721 microseconds"
          },
          {
            "name": "calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 223.35359172062715,
            "range": "±1.72%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 447\nmean latency: 4477 microseconds"
          },
          {
            "name": "calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 90.16000661505463,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 181\nmean latency: 11091 microseconds"
          },
          {
            "name": "calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 133.7422118865886,
            "range": "±0.63%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 268\nmean latency: 7477 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 412.09161720734755,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 825\nmean latency: 2427 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 7797.902526218422,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 15596\nmean latency: 128 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 247.82899799138593,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 496\nmean latency: 4035 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 5133.999435055082,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 10269\nmean latency: 195 microseconds"
          },
          {
            "name": "synctree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 168.95548023095915,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 338\nmean latency: 5919 microseconds"
          },
          {
            "name": "synctree merge write path userMerge only [wasm]",
            "value": 380.0619785696984,
            "range": "±1.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 761\nmean latency: 2631 microseconds"
          },
          {
            "name": "synctree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 394.4057370288501,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 789\nmean latency: 2535 microseconds"
          },
          {
            "name": "synctree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 1045.6805445936266,
            "range": "±0.84%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2092\nmean latency: 956 microseconds"
          }
        ]
      }
    ]
  }
}