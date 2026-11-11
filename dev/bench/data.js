window.BENCHMARK_DATA = {
  "lastUpdate": 1794436010878,
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
          "id": "6196a91a3aed524a55f1e16a959cc89d5755f50c",
          "message": "fix: load Wasm benchmarks with the current dart2wasm loader\n\nFlutter 3.47.9 pins test_api 0.7.12, which keeps package:test on 1.31.1.\nThat release still calls the removed Wasm instantiate export. Pin test\n1.31.2 with the matching test_api and test_core so the Node Wasm suite loads.\nRequire sortedmap 0.5.5+1 so a filtered map copies only the visible window.\n\nCo-authored-by: Cursor <cursoragent@cursor.com>",
          "timestamp": "2026-11-11T14:48:04+01:00",
          "tree_id": "ac9278c3eee1dd417ba9612cf660e0098316db34",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/6196a91a3aed524a55f1e16a959cc89d5755f50c"
        },
        "date": 1794433378062,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1959.3677426773693,
            "range": "±1.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3919\nmean latency: 510 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 465.37527942511406,
            "range": "±0.76%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 931\nmean latency: 2149 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 524.116870567615,
            "range": "±0.60%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1049\nmean latency: 1908 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 2409.7578193391564,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4820\nmean latency: 415 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 25636.064186908825,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 51273\nmean latency: 39 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 7087.659792329969,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 14176\nmean latency: 141 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 10915.227119322017,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 21831\nmean latency: 92 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [jit]",
            "value": 70127.42987257012,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 140255\nmean latency: 14 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [jit]",
            "value": 70140.28957913126,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 140281\nmean latency: 14 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [jit]",
            "value": 4994.485016544951,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9989\nmean latency: 200 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [jit]",
            "value": 203708.09258381484,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 407417\nmean latency: 5 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [jit]",
            "value": 3855342.0000000005,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7710684\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [jit]",
            "value": 6451.664513445301,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 12904\nmean latency: 155 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [jit]",
            "value": 2827.9109208059945,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5656\nmean latency: 354 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [jit]",
            "value": 409405.5,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 818811\nmean latency: 2 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [jit]",
            "value": 1090749.5,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2181499\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [jit]",
            "value": 69250.39612440582,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 138501\nmean latency: 14 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [jit]",
            "value": 69462.93053706946,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 138926\nmean latency: 14 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [jit]",
            "value": 417.77022637549345,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 836\nmean latency: 2394 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [jit]",
            "value": 177939.14412171175,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 355879\nmean latency: 6 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [jit]",
            "value": 3835524.0000000005,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7671048\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [jit]",
            "value": 496.9525410323314,
            "range": "±0.87%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 994\nmean latency: 2012 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [jit]",
            "value": 223.7867312451234,
            "range": "±1.37%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 448\nmean latency: 4469 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [jit]",
            "value": 352651.64734835265,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 705304\nmean latency: 3 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [jit]",
            "value": 882489,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1764978\nmean latency: 1 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [jit]",
            "value": 69099.5,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 138199\nmean latency: 14 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [jit]",
            "value": 4992.947574050473,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9986\nmean latency: 200 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [jit]",
            "value": 4603.428646855974,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9207\nmean latency: 217 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [jit]",
            "value": 69818.19709073345,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 139638\nmean latency: 14 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [jit]",
            "value": 424.96175344219023,
            "range": "±1.45%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 850\nmean latency: 2353 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [jit]",
            "value": 417.4171426971746,
            "range": "±1.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 835\nmean latency: 2396 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [jit]",
            "value": 65229.83692540768,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 130460\nmean latency: 15 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [jit]",
            "value": 4922.83754636097,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9846\nmean latency: 203 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [jit]",
            "value": 740376,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1480752\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [jit]",
            "value": 19852.67243090489,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 39706\nmean latency: 50 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [jit]",
            "value": 2314.283614482046,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4629\nmean latency: 432 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [jit]",
            "value": 13701.77392073031,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 27404\nmean latency: 73 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [jit]",
            "value": 7385.392911802778,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 14771\nmean latency: 135 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [jit]",
            "value": 2219461,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4438922\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [jit]",
            "value": 334725.1652748347,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 669451\nmean latency: 3 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [jit]",
            "value": 1238892,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2477784\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [jit]",
            "value": 65289.640906975015,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 130580\nmean latency: 15 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [jit]",
            "value": 431.36325784726245,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 863\nmean latency: 2318 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [jit]",
            "value": 774409,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1548818\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [jit]",
            "value": 19608.94117317648,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 39218\nmean latency: 51 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [jit]",
            "value": 203.73819641760335,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 408\nmean latency: 4908 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [jit]",
            "value": 1155.7509356733624,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2312\nmean latency: 865 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [jit]",
            "value": 7267.151176743517,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 14535\nmean latency: 138 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [jit]",
            "value": 2256069.5,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4512139\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [jit]",
            "value": 332831.1671688328,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 665663\nmean latency: 3 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [jit]",
            "value": 1252606,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2505212\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 1291.3547225937082,
            "range": "±0.91%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2583\nmean latency: 774 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [jit]",
            "value": 3501.6095705328858,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7004\nmean latency: 286 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 2901.204077184127,
            "range": "±0.48%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5803\nmean latency: 345 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [jit]",
            "value": 6170.160641164735,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 12341\nmean latency: 162 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [jit]",
            "value": 72036.85592628815,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 144074\nmean latency: 14 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [jit]",
            "value": 4923.785815317034,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9848\nmean latency: 203 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [jit]",
            "value": 3427706.5000000005,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6855413\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [jit]",
            "value": 240356.3798218101,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 480713\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [jit]",
            "value": 454169,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 908338\nmean latency: 2 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [jit]",
            "value": 72072,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 144144\nmean latency: 14 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [jit]",
            "value": 441.6683071013669,
            "range": "±0.89%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 884\nmean latency: 2264 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [jit]",
            "value": 3509895,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7019790\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [jit]",
            "value": 208905.79109420892,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 417812\nmean latency: 5 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [jit]",
            "value": 335514.5,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 671029\nmean latency: 3 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 2272.2739087460795,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4545\nmean latency: 440 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 513.6956353360634,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1028\nmean latency: 1947 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 590.2683196845238,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1181\nmean latency: 1694 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 2388.7885922095893,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4778\nmean latency: 419 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 21481.87110877335,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 42964\nmean latency: 47 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 6764.536629240896,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 13530\nmean latency: 148 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 9974.385294569112,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 19949\nmean latency: 100 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [aot]",
            "value": 58458.38308323384,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 116917\nmean latency: 17 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [aot]",
            "value": 58361.649830101014,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 116724\nmean latency: 17 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [aot]",
            "value": 4100.811362677317,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8202\nmean latency: 244 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [aot]",
            "value": 192344.30765569236,
            "range": "±0.10%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 384689\nmean latency: 5 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [aot]",
            "value": 5132180,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10264360\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [aot]",
            "value": 5602.966382201706,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 11206\nmean latency: 178 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [aot]",
            "value": 2424.2393942651165,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4849\nmean latency: 413 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [aot]",
            "value": 415221,
            "range": "±0.11%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 830442\nmean latency: 2 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [aot]",
            "value": 1038215.5,
            "range": "±0.10%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2076431\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [aot]",
            "value": 58126.970936514525,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 116254\nmean latency: 17 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [aot]",
            "value": 58293.20853395733,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 116587\nmean latency: 17 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [aot]",
            "value": 355.0703648585212,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 711\nmean latency: 2816 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [aot]",
            "value": 164353,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 328706\nmean latency: 6 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [aot]",
            "value": 5103073.5,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10206147\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [aot]",
            "value": 426.1092578105877,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 853\nmean latency: 2347 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [aot]",
            "value": 190.70497939687303,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 382\nmean latency: 5244 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [aot]",
            "value": 356265.1437348563,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 712531\nmean latency: 3 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [aot]",
            "value": 798966,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1597932\nmean latency: 1 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [aot]",
            "value": 58288.73770068034,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 116578\nmean latency: 17 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [aot]",
            "value": 4055.147202193409,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8111\nmean latency: 247 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [aot]",
            "value": 3837.210290623058,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7675\nmean latency: 261 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [aot]",
            "value": 56279.331162006514,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 112559\nmean latency: 18 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [aot]",
            "value": 354.7444066550051,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 710\nmean latency: 2819 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [aot]",
            "value": 352.60156023693224,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 706\nmean latency: 2836 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [aot]",
            "value": 54988.80753917362,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 109978\nmean latency: 18 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [aot]",
            "value": 4058.1996932227016,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8117\nmean latency: 246 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [aot]",
            "value": 956409.9999999999,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1912820\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [aot]",
            "value": 17267.310059589345,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 34535\nmean latency: 58 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [aot]",
            "value": 1946.9503527660045,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3894\nmean latency: 514 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [aot]",
            "value": 12940.962950037574,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 25883\nmean latency: 77 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [aot]",
            "value": 6940.705020036648,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 13882\nmean latency: 144 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [aot]",
            "value": 2915836,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5831672\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [aot]",
            "value": 413903.7930481035,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 827808\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [aot]",
            "value": 1474939.5,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2949879\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [aot]",
            "value": 53733.75819808811,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 107468\nmean latency: 19 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [aot]",
            "value": 359.98632051982025,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 720\nmean latency: 2778 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [aot]",
            "value": 950271.5,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1900543\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [aot]",
            "value": 16652.067046256798,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 33305\nmean latency: 60 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [aot]",
            "value": 174.40564654521904,
            "range": "±1.34%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 349\nmean latency: 5734 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [aot]",
            "value": 1036.6387314021065,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2074\nmean latency: 965 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [aot]",
            "value": 6874.26283793209,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 13749\nmean latency: 145 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [aot]",
            "value": 2978255,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5956510\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [aot]",
            "value": 421022.5,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 842045\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [aot]",
            "value": 1486207,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2972414\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 1452.0752679841146,
            "range": "±0.49%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2905\nmean latency: 689 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [aot]",
            "value": 3803.804104088639,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7608\nmean latency: 263 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 3214.853724155551,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 6430\nmean latency: 311 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [aot]",
            "value": 6752.263670771524,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 13505\nmean latency: 148 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [aot]",
            "value": 59486.61333701332,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 118974\nmean latency: 17 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [aot]",
            "value": 4182.410078183319,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8365\nmean latency: 239 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [aot]",
            "value": 4469529,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8939058\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [aot]",
            "value": 230309.1545362682,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 460619\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [aot]",
            "value": 383696,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 767392\nmean latency: 3 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [aot]",
            "value": 58823.41176488235,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 117647\nmean latency: 17 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [aot]",
            "value": 377.15716413779876,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 755\nmean latency: 2651 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [aot]",
            "value": 4557173,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9114346\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [aot]",
            "value": 197055.10588978822,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 394111\nmean latency: 5 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [aot]",
            "value": 277654.36117281945,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 555309\nmean latency: 4 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 354.32283858070963,
            "range": "±1.99%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 709\nmean latency: 2822 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 109.00000000000001,
            "range": "±0.76%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 218\nmean latency: 9174 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 135.9320339830085,
            "range": "±0.90%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 272\nmean latency: 7357 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 156.0319042871386,
            "range": "±1.03%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 313\nmean latency: 6409 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 3179.9999999999995,
            "range": "±3.63%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 6360\nmean latency: 314 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 859.0704647676163,
            "range": "±1.58%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1719\nmean latency: 1164 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1438.5,
            "range": "±2.43%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2877\nmean latency: 695 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [js]",
            "value": 7174.5,
            "range": "±4.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14349\nmean latency: 139 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [js]",
            "value": 7209.999999999999,
            "range": "±4.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14420\nmean latency: 139 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [js]",
            "value": 569.5,
            "range": "±1.48%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1139\nmean latency: 1756 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [js]",
            "value": 14676,
            "range": "±4.23%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 29352\nmean latency: 68 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [js]",
            "value": 823938.5,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1647877\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [js]",
            "value": 749.0000000000001,
            "range": "±1.80%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1498\nmean latency: 1335 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [js]",
            "value": 338.33083458270863,
            "range": "±0.72%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 677\nmean latency: 2956 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [js]",
            "value": 56419.99999999999,
            "range": "±4.34%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 112840\nmean latency: 18 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [js]",
            "value": 134645,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 269290\nmean latency: 7 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [js]",
            "value": 7191,
            "range": "±4.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14382\nmean latency: 139 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [js]",
            "value": 7109.999999999999,
            "range": "±4.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14220\nmean latency: 141 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [js]",
            "value": 49.6031746031746,
            "range": "±0.70%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 100\nmean latency: 20160 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [js]",
            "value": 2806,
            "range": "±3.52%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 5612\nmean latency: 356 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [js]",
            "value": 843029.4999999999,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1686059\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [js]",
            "value": 58.8235294117647,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 118\nmean latency: 17000 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [js]",
            "value": 26.799007444168733,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 54\nmean latency: 37315 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [js]",
            "value": 48987,
            "range": "±4.34%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 97974\nmean latency: 20 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [js]",
            "value": 107153.5,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 214307\nmean latency: 9 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [js]",
            "value": 7173,
            "range": "±4.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14346\nmean latency: 139 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [js]",
            "value": 569.5,
            "range": "±1.43%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1139\nmean latency: 1756 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [js]",
            "value": 513.7431284357821,
            "range": "±0.89%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1028\nmean latency: 1946 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [js]",
            "value": 7175.499999999999,
            "range": "±4.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14351\nmean latency: 139 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [js]",
            "value": 50.24875621890547,
            "range": "±0.49%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 101\nmean latency: 19901 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [js]",
            "value": 48.61111111111111,
            "range": "±0.70%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 98\nmean latency: 20571 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [js]",
            "value": 6794.5,
            "range": "±4.05%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 13589\nmean latency: 147 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [js]",
            "value": 559.5,
            "range": "±1.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1119\nmean latency: 1787 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [js]",
            "value": 161592.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 323185\nmean latency: 6 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [js]",
            "value": 1908.9999999999998,
            "range": "±3.02%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3818\nmean latency: 524 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [js]",
            "value": 262.3688155922039,
            "range": "±1.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 525\nmean latency: 3811 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [js]",
            "value": 1519.5,
            "range": "±2.58%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3039\nmean latency: 658 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [js]",
            "value": 842.5787106446777,
            "range": "±1.57%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1686\nmean latency: 1187 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [js]",
            "value": 274246,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 548492\nmean latency: 4 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [js]",
            "value": 58771.5,
            "range": "±4.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 117543\nmean latency: 17 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [js]",
            "value": 185715.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 371431\nmean latency: 5 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [js]",
            "value": 6879,
            "range": "±4.06%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 13758\nmean latency: 145 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [js]",
            "value": 49.72650422675286,
            "range": "±0.48%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 100\nmean latency: 20110 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [js]",
            "value": 162980,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 325960\nmean latency: 6 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [js]",
            "value": 1242,
            "range": "±1.98%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2484\nmean latency: 805 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [js]",
            "value": 24.61841457410143,
            "range": "±0.49%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 50\nmean latency: 40620 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [js]",
            "value": 141.35864135864136,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 283\nmean latency: 7074 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [js]",
            "value": 827,
            "range": "±1.63%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1654\nmean latency: 1209 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [js]",
            "value": 272832,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 545664\nmean latency: 4 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [js]",
            "value": 58499.00000000001,
            "range": "±4.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 116998\nmean latency: 17 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [js]",
            "value": 181223,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 362446\nmean latency: 6 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 189.8101898101898,
            "range": "±1.33%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 380\nmean latency: 5268 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [js]",
            "value": 499.5004995004995,
            "range": "±0.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1000\nmean latency: 2002 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 425.7871064467766,
            "range": "±1.48%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 852\nmean latency: 2349 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [js]",
            "value": 961.5,
            "range": "±0.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1923\nmean latency: 1040 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [js]",
            "value": 6981.5,
            "range": "±4.06%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 13963\nmean latency: 143 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [js]",
            "value": 552.7236381809096,
            "range": "±1.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1106\nmean latency: 1809 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [js]",
            "value": 100532,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 201064\nmean latency: 10 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [js]",
            "value": 15354.000000000002,
            "range": "±4.24%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 30708\nmean latency: 65 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [js]",
            "value": 21105.5,
            "range": "±4.28%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 42211\nmean latency: 47 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [js]",
            "value": 7122.000000000001,
            "range": "±4.06%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14244\nmean latency: 140 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [js]",
            "value": 49.77600796416127,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 100\nmean latency: 20090 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [js]",
            "value": 99416.5,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 198833\nmean latency: 10 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [js]",
            "value": 2891.5,
            "range": "±3.55%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 5783\nmean latency: 346 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [js]",
            "value": 3109.5,
            "range": "±3.61%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 6219\nmean latency: 322 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 831.3802812395014,
            "range": "±1.04%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1663\nmean latency: 1203 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 187.27957194382213,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 375\nmean latency: 5340 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 234.54311002167776,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 470\nmean latency: 4264 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 586.694918642306,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1174\nmean latency: 1704 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 10426.48436027346,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 20853\nmean latency: 96 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 2817.342228835185,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 5635\nmean latency: 355 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 5103.46427575007,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 10207\nmean latency: 196 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [wasm]",
            "value": 25937.383281775234,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 51875\nmean latency: 39 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [wasm]",
            "value": 25908.676141548232,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 51818\nmean latency: 39 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [wasm]",
            "value": 1753.080137307115,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3507\nmean latency: 570 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [wasm]",
            "value": 58564.707176464115,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 117130\nmean latency: 17 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [wasm]",
            "value": 5654656,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 11309312\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [wasm]",
            "value": 2590.9261586044795,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 5182\nmean latency: 386 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [wasm]",
            "value": 1084.0652898187827,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2169\nmean latency: 922 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [wasm]",
            "value": 192605.40369729814,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 385211\nmean latency: 5 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [wasm]",
            "value": 499283.75035812485,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 998568\nmean latency: 2 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [wasm]",
            "value": 25734.1268551606,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 51469\nmean latency: 39 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [wasm]",
            "value": 25599.74400255997,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 51200\nmean latency: 39 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [wasm]",
            "value": 147.92241469349327,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 296\nmean latency: 6760 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [wasm]",
            "value": 10834.402490377586,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 21669\nmean latency: 92 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [wasm]",
            "value": 5719533.5,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 11439067\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [wasm]",
            "value": 194.2618349903019,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 389\nmean latency: 5148 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [wasm]",
            "value": 76.94694508136641,
            "range": "±0.82%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 154\nmean latency: 12996 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [wasm]",
            "value": 167492.6328020551,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 334999\nmean latency: 6 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [wasm]",
            "value": 382322.3088388456,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 764645\nmean latency: 3 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [wasm]",
            "value": 25956.727454361728,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 51914\nmean latency: 39 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [wasm]",
            "value": 1770.5281542468933,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3542\nmean latency: 565 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [wasm]",
            "value": 1618.8089805402963,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3238\nmean latency: 618 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [wasm]",
            "value": 25603.33357833174,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 51207\nmean latency: 39 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [wasm]",
            "value": 150.35686026902388,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 301\nmean latency: 6651 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [wasm]",
            "value": 143.61604251034856,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 288\nmean latency: 6963 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [wasm]",
            "value": 24419.048247607418,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 48839\nmean latency: 41 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [wasm]",
            "value": 1759.808180908281,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3520\nmean latency: 568 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [wasm]",
            "value": 501489.5,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1002979\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [wasm]",
            "value": 7351.422810060495,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14703\nmean latency: 136 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [wasm]",
            "value": 827.8323639463008,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1656\nmean latency: 1208 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [wasm]",
            "value": 6301.37397252055,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 12603\nmean latency: 159 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [wasm]",
            "value": 3165.827462403299,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 6332\nmean latency: 316 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [wasm]",
            "value": 1763779.9999999998,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3527560\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [wasm]",
            "value": 172132.82786717213,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 344266\nmean latency: 6 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [wasm]",
            "value": 691861.6540691729,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1383724\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [wasm]",
            "value": 24045.903816384736,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 48092\nmean latency: 42 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [wasm]",
            "value": 141.99226142175252,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 284\nmean latency: 7043 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [wasm]",
            "value": 489718.25514087244,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 979437\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [wasm]",
            "value": 4348.004327506664,
            "range": "±0.48%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8697\nmean latency: 230 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [wasm]",
            "value": 70.03635930142457,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 141\nmean latency: 14278 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [wasm]",
            "value": 523.3866867823116,
            "range": "±1.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1047\nmean latency: 1911 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [wasm]",
            "value": 3072.3771049158036,
            "range": "±0.56%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 6145\nmean latency: 325 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [wasm]",
            "value": 1766556.0000000002,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3533112\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [wasm]",
            "value": 172441.27479028318,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 344896\nmean latency: 6 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [wasm]",
            "value": 729034,
            "range": "±0.07%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1458068\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 565.7974445148636,
            "range": "±0.59%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1132\nmean latency: 1767 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [wasm]",
            "value": 1487.5559645445833,
            "range": "±0.58%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2976\nmean latency: 672 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 1362.8603068185512,
            "range": "±0.57%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2726\nmean latency: 734 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 2488.3954873895295,
            "range": "±0.56%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4977\nmean latency: 402 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [wasm]",
            "value": 25727.229864086425,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 51455\nmean latency: 39 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [wasm]",
            "value": 1703.7708428216404,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3408\nmean latency: 587 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [wasm]",
            "value": 285824.0712638931,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 571649\nmean latency: 3 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [wasm]",
            "value": 66714.79985560043,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 133430\nmean latency: 15 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [wasm]",
            "value": 93790.5,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 187581\nmean latency: 11 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [wasm]",
            "value": 25763.5,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 51527\nmean latency: 39 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [wasm]",
            "value": 146.7269411624966,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 294\nmean latency: 6815 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [wasm]",
            "value": 277316.36134181934,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 554633\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [wasm]",
            "value": 10982.154062147043,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 21965\nmean latency: 91 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [wasm]",
            "value": 11703.201568360006,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 23407\nmean latency: 85 microseconds"
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
          "id": "c05fe0c88ce35a9f1010a5676311d729818ee194",
          "message": "perf: serve an indexed withFilter from a sorted child map\n\naddIndex stores the children in the requested ordering. withFilter reads that map instead of sorting every child again.\n\nCo-authored-by: Cursor <cursoragent@cursor.com>",
          "timestamp": "2026-11-11T14:48:31+01:00",
          "tree_id": "69ff052d0156765eb14b4ee069b67521c8e5af2b",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/c05fe0c88ce35a9f1010a5676311d729818ee194"
        },
        "date": 1794434134648,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1385.7013813523185,
            "range": "±2.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2772\nmean latency: 722 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 347.96624727401445,
            "range": "±0.77%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 696\nmean latency: 2874 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 401.77520677181116,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 804\nmean latency: 2489 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1809.731254908646,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3620\nmean latency: 553 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 19450.659613456766,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 38902\nmean latency: 51 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 5305.909799533409,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10612\nmean latency: 188 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 8455,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 16910\nmean latency: 118 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [jit]",
            "value": 50271.64809846331,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 100544\nmean latency: 20 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [jit]",
            "value": 51774.5,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 103549\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [jit]",
            "value": 3668.855080224331,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7338\nmean latency: 273 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [jit]",
            "value": 154361.69127661744,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 308724\nmean latency: 6 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [jit]",
            "value": 3049939.5,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6099879\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [jit]",
            "value": 4793.444875383933,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9587\nmean latency: 209 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [jit]",
            "value": 2173.82935439568,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4348\nmean latency: 460 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [jit]",
            "value": 329451.8352740823,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 658904\nmean latency: 3 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [jit]",
            "value": 841484.5000000001,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1682969\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [jit]",
            "value": 51588.26785279466,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 103177\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [jit]",
            "value": 50649.34805195584,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 101299\nmean latency: 20 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [jit]",
            "value": 319.376880212678,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 639\nmean latency: 3131 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [jit]",
            "value": 135188.5,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 270377\nmean latency: 7 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [jit]",
            "value": 3056726,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6113452\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [jit]",
            "value": 391.4907999662008,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 783\nmean latency: 2554 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [jit]",
            "value": 175.61925744984873,
            "range": "±0.88%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 352\nmean latency: 5694 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [jit]",
            "value": 287591.8562040719,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 575184\nmean latency: 3 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [jit]",
            "value": 667312.6663436668,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1334626\nmean latency: 1 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [jit]",
            "value": 51538.92269161596,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 103078\nmean latency: 19 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [jit]",
            "value": 3723.338034795486,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 7447\nmean latency: 269 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [jit]",
            "value": 3305.485125316936,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6611\nmean latency: 303 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [jit]",
            "value": 51274.615440384194,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 102550\nmean latency: 20 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [jit]",
            "value": 328.296620243759,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 657\nmean latency: 3046 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [jit]",
            "value": 321.9971020260818,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 644\nmean latency: 3106 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [jit]",
            "value": 47210,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 94420\nmean latency: 21 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [jit]",
            "value": 3404.897853064408,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6810\nmean latency: 294 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [jit]",
            "value": 601349.5,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1202699\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [jit]",
            "value": 14060.324245946927,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 28121\nmean latency: 71 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [jit]",
            "value": 1673.300040645143,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3347\nmean latency: 598 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [jit]",
            "value": 9917.692551530903,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 19836\nmean latency: 101 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [jit]",
            "value": 5503.169809811411,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 11007\nmean latency: 182 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [jit]",
            "value": 1861332,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3722664\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [jit]",
            "value": 263381.3683093159,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 526763\nmean latency: 4 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [jit]",
            "value": 975599.9999999999,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1951200\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [jit]",
            "value": 48336.33082284212,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 96673\nmean latency: 21 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [jit]",
            "value": 315.59367314582477,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 632\nmean latency: 3169 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [jit]",
            "value": 607324.5,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1214649\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [jit]",
            "value": 14142.759573087256,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 28286\nmean latency: 71 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [jit]",
            "value": 151.3705781556769,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 303\nmean latency: 6606 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [jit]",
            "value": 879.7822538921617,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1760\nmean latency: 1137 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [jit]",
            "value": 5421.810236641717,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10844\nmean latency: 184 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [jit]",
            "value": 1870540.888377335,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3741093\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [jit]",
            "value": 267319.36634031683,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 534639\nmean latency: 4 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [jit]",
            "value": 964218.5,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1928437\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 909.2195057824662,
            "range": "±1.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1819\nmean latency: 1100 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [jit]",
            "value": 2560.132620968891,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5121\nmean latency: 391 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 2231.6697128824935,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4464\nmean latency: 448 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [jit]",
            "value": 4724.485826542521,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9449\nmean latency: 212 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [jit]",
            "value": 51493.716784557684,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 102988\nmean latency: 19 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [jit]",
            "value": 45202.773986130065,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 90406\nmean latency: 22 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [jit]",
            "value": 2837985,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5675970\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [jit]",
            "value": 100274.44986277506,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 200549\nmean latency: 10 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [jit]",
            "value": 175627.41218629392,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 351255\nmean latency: 6 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [jit]",
            "value": 51696.534731187414,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 103394\nmean latency: 19 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [jit]",
            "value": 44811.3655659033,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 89623\nmean latency: 22 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [jit]",
            "value": 2828576.5,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5657153\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [jit]",
            "value": 82417.62912066896,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 164836\nmean latency: 12 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [jit]",
            "value": 129395,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 258790\nmean latency: 8 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1661.9484795971325,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3324\nmean latency: 602 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 377.5725878305758,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 756\nmean latency: 2648 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 436.3442251116352,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 873\nmean latency: 2292 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1727.338493850825,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3455\nmean latency: 579 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 16327.091822704431,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 32655\nmean latency: 61 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 4756.598067463299,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9514\nmean latency: 210 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 7170.899607405497,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 14342\nmean latency: 139 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [aot]",
            "value": 43241.84865352971,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 86484\nmean latency: 23 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [aot]",
            "value": 42842.89289276777,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 85686\nmean latency: 23 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [aot]",
            "value": 3007.521804033159,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 6016\nmean latency: 332 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [aot]",
            "value": 144714.2829285756,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 289429\nmean latency: 7 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [aot]",
            "value": 4268243,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8536486\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [aot]",
            "value": 4198.796358376619,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8398\nmean latency: 238 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [aot]",
            "value": 1803.8520841291013,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3608\nmean latency: 554 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [aot]",
            "value": 308591.84570407716,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 617184\nmean latency: 3 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [aot]",
            "value": 837367,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1674734\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [aot]",
            "value": 42189.87343037971,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 84380\nmean latency: 24 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [aot]",
            "value": 42294.68278987908,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 84590\nmean latency: 24 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [aot]",
            "value": 265.4565978462521,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 531\nmean latency: 3767 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [aot]",
            "value": 126002.3109965335,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 252005\nmean latency: 8 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [aot]",
            "value": 4306998.5,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 8613997\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [aot]",
            "value": 328.9213877883186,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 658\nmean latency: 3040 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [aot]",
            "value": 139.7908728542101,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 280\nmean latency: 7154 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [aot]",
            "value": 268258.86587056704,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 536518\nmean latency: 4 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [aot]",
            "value": 648090.675954662,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1296182\nmean latency: 2 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [aot]",
            "value": 43272.43509134736,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 86545\nmean latency: 23 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [aot]",
            "value": 3047.9527567322702,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 6096\nmean latency: 328 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [aot]",
            "value": 2788.6890611696795,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5578\nmean latency: 359 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [aot]",
            "value": 42441.05436892913,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 84883\nmean latency: 24 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [aot]",
            "value": 262.42822588022176,
            "range": "±0.70%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 525\nmean latency: 3811 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [aot]",
            "value": 256.37719532344005,
            "range": "±1.01%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 513\nmean latency: 3901 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [aot]",
            "value": 39652.222434442956,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 79305\nmean latency: 25 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [aot]",
            "value": 2944.9072354220843,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5890\nmean latency: 340 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [aot]",
            "value": 716434,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1432868\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [aot]",
            "value": 12639.99368000316,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 25280\nmean latency: 79 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [aot]",
            "value": 1430.5622479521267,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2862\nmean latency: 699 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [aot]",
            "value": 9437.155543822651,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 18875\nmean latency: 106 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [aot]",
            "value": 5197.9194322488,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10396\nmean latency: 192 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [aot]",
            "value": 2309201,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4618402\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [aot]",
            "value": 322804.1771958228,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 645609\nmean latency: 3 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [aot]",
            "value": 1142550.5,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2285101\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [aot]",
            "value": 40901,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 81802\nmean latency: 24 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [aot]",
            "value": 264.9377396311867,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 530\nmean latency: 3774 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [aot]",
            "value": 728735.5,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1457471\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [aot]",
            "value": 12541.067333177005,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 25083\nmean latency: 80 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [aot]",
            "value": 131.56517708971847,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 264\nmean latency: 7601 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [aot]",
            "value": 772.6712283923191,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1546\nmean latency: 1294 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [aot]",
            "value": 5086.552383390262,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 10174\nmean latency: 197 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [aot]",
            "value": 2308340.5,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4616681\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [aot]",
            "value": 320172.1798278202,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 640345\nmean latency: 3 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [aot]",
            "value": 1145655,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2291310\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 1041.7130080662778,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2084\nmean latency: 960 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [aot]",
            "value": 2776.540482550138,
            "range": "±0.55%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5554\nmean latency: 360 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 2344.385125128869,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4689\nmean latency: 427 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [aot]",
            "value": 4937.548214338388,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9876\nmean latency: 203 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [aot]",
            "value": 44035.82385670457,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 88072\nmean latency: 23 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [aot]",
            "value": 37257.981371009315,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 74516\nmean latency: 27 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [aot]",
            "value": 3849724.5,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7699449\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [aot]",
            "value": 89154.41084558915,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 178309\nmean latency: 11 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [aot]",
            "value": 141872.6453183867,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 283746\nmean latency: 7 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [aot]",
            "value": 43784.30297063663,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 87569\nmean latency: 23 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [aot]",
            "value": 36991.98150400925,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 73984\nmean latency: 27 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [aot]",
            "value": 3854837,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7709674\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [aot]",
            "value": 69705.08176950939,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 139411\nmean latency: 14 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [aot]",
            "value": 101572.04292580685,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 203145\nmean latency: 10 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 235.14727908137795,
            "range": "±2.67%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 471\nmean latency: 4253 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 76.61691542288558,
            "range": "±1.27%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 154\nmean latency: 13052 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 99.65122072745392,
            "range": "±1.00%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 200\nmean latency: 10035 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 114.59890383657199,
            "range": "±1.13%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 230\nmean latency: 8726 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2320.5,
            "range": "±3.31%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4641\nmean latency: 431 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 670.5,
            "range": "±1.86%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1341\nmean latency: 1491 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1087,
            "range": "±1.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2174\nmean latency: 920 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [js]",
            "value": 5568.5,
            "range": "±3.97%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 11137\nmean latency: 180 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [js]",
            "value": 5614,
            "range": "±3.97%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 11228\nmean latency: 178 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [js]",
            "value": 440.00000000000006,
            "range": "±1.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 880\nmean latency: 2273 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [js]",
            "value": 10292,
            "range": "±4.16%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 20584\nmean latency: 97 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [js]",
            "value": 671333,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1342666\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [js]",
            "value": 571,
            "range": "±1.60%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1142\nmean latency: 1751 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [js]",
            "value": 259.7402597402597,
            "range": "±0.97%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 520\nmean latency: 3850 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [js]",
            "value": 39460,
            "range": "±4.33%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 78920\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [js]",
            "value": 106511.49999999999,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 213023\nmean latency: 9 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [js]",
            "value": 5594,
            "range": "±3.98%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 11188\nmean latency: 179 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [js]",
            "value": 5598.5,
            "range": "±3.98%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 11197\nmean latency: 179 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [js]",
            "value": 38.86397608370702,
            "range": "±0.84%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 78\nmean latency: 25731 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [js]",
            "value": 2004.5,
            "range": "±3.11%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4009\nmean latency: 499 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [js]",
            "value": 683963.5,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1367927\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [js]",
            "value": 45.0272142503711,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 91\nmean latency: 22209 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [js]",
            "value": 20.659124446630592,
            "range": "±1.30%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 42\nmean latency: 48405 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [js]",
            "value": 34584,
            "range": "±4.32%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 69168\nmean latency: 29 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [js]",
            "value": 83106.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 166213\nmean latency: 12 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [js]",
            "value": 5601.5,
            "range": "±3.97%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 11203\nmean latency: 179 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [js]",
            "value": 438.06193806193806,
            "range": "±1.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 877\nmean latency: 2283 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [js]",
            "value": 394.10589410589415,
            "range": "±1.41%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 789\nmean latency: 2537 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [js]",
            "value": 5611.5,
            "range": "±3.98%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 11223\nmean latency: 178 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [js]",
            "value": 39.24490809736711,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 79\nmean latency: 25481 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [js]",
            "value": 37.62376237623762,
            "range": "±0.56%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 76\nmean latency: 26579 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [js]",
            "value": 5167,
            "range": "±3.94%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10334\nmean latency: 194 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [js]",
            "value": 429.57042957042955,
            "range": "±1.39%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 860\nmean latency: 2328 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [js]",
            "value": 128028,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 256056\nmean latency: 8 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [js]",
            "value": 1395,
            "range": "±2.40%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2790\nmean latency: 717 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [js]",
            "value": 199.49999999999997,
            "range": "±1.01%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 399\nmean latency: 5013 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [js]",
            "value": 1085.5,
            "range": "±1.32%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2171\nmean latency: 921 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [js]",
            "value": 629,
            "range": "±1.77%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1258\nmean latency: 1590 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [js]",
            "value": 214698,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 429396\nmean latency: 5 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [js]",
            "value": 43993.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 87987\nmean latency: 23 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [js]",
            "value": 143193,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 286386\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [js]",
            "value": 5213,
            "range": "±3.94%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10426\nmean latency: 192 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [js]",
            "value": 38.17550818046604,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 77\nmean latency: 26195 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [js]",
            "value": 127191.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 254383\nmean latency: 8 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [js]",
            "value": 919,
            "range": "±1.21%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1838\nmean latency: 1088 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [js]",
            "value": 18.435475834578973,
            "range": "±0.55%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 37\nmean latency: 54243 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [js]",
            "value": 101.44927536231884,
            "range": "±0.66%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 203\nmean latency: 9857 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [js]",
            "value": 629,
            "range": "±1.74%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1258\nmean latency: 1590 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [js]",
            "value": 216555.49999999997,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 433111\nmean latency: 5 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [js]",
            "value": 43752,
            "range": "±4.33%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 87504\nmean latency: 23 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [js]",
            "value": 144077.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 288155\nmean latency: 7 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 138.93053473263367,
            "range": "±1.89%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 278\nmean latency: 7198 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [js]",
            "value": 365.13486513486515,
            "range": "±1.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 731\nmean latency: 2739 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 313.5,
            "range": "±0.98%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 627\nmean latency: 3190 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [js]",
            "value": 703,
            "range": "±1.83%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1406\nmean latency: 1422 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [js]",
            "value": 5359,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10718\nmean latency: 187 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [js]",
            "value": 4693.5,
            "range": "±3.89%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9387\nmean latency: 213 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [js]",
            "value": 79338,
            "range": "±4.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 158676\nmean latency: 13 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [js]",
            "value": 6873.5,
            "range": "±4.06%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 13747\nmean latency: 145 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [js]",
            "value": 10456,
            "range": "±4.17%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 20912\nmean latency: 96 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [js]",
            "value": 5408.5,
            "range": "±3.96%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10817\nmean latency: 185 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [js]",
            "value": 4724,
            "range": "±3.89%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9448\nmean latency: 212 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [js]",
            "value": 78131,
            "range": "±4.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 156262\nmean latency: 13 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [js]",
            "value": 1736.5,
            "range": "±2.86%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3473\nmean latency: 576 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [js]",
            "value": 1885,
            "range": "±3.01%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3770\nmean latency: 531 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 627.8926303602084,
            "range": "±1.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1256\nmean latency: 1593 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 156.27293542482772,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 313\nmean latency: 6399 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 192.99942100173698,
            "range": "±0.89%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 386\nmean latency: 5181 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 448.65005295869224,
            "range": "±0.60%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 898\nmean latency: 2229 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 8426.268277622365,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 16853\nmean latency: 119 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 2288.2528686901815,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4577\nmean latency: 437 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 4095.2174299973303,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8191\nmean latency: 244 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [wasm]",
            "value": 20703.24120948488,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 41407\nmean latency: 48 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [wasm]",
            "value": 20631.577052670422,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 41264\nmean latency: 48 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [wasm]",
            "value": 1476.250513663191,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2953\nmean latency: 677 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [wasm]",
            "value": 46779.17254579218,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 93559\nmean latency: 21 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [wasm]",
            "value": 4351171,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8702342\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [wasm]",
            "value": 2116.954485478562,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4234\nmean latency: 472 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [wasm]",
            "value": 890.4995547502225,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1781\nmean latency: 1123 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [wasm]",
            "value": 161125,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 322250\nmean latency: 6 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [wasm]",
            "value": 408162.79591860203,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 816326\nmean latency: 2 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [wasm]",
            "value": 20434.13218562066,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 40869\nmean latency: 49 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [wasm]",
            "value": 20645.587088258235,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 41292\nmean latency: 48 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [wasm]",
            "value": 123.6754138762817,
            "range": "±0.75%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 248\nmean latency: 8086 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [wasm]",
            "value": 7311.652696496916,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14624\nmean latency: 137 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [wasm]",
            "value": 4345982,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8691964\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [wasm]",
            "value": 154.25257886350295,
            "range": "±0.83%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 309\nmean latency: 6483 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [wasm]",
            "value": 63.85766127302243,
            "range": "±0.90%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 128\nmean latency: 15660 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [wasm]",
            "value": 136598.3634016366,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 273197\nmean latency: 7 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [wasm]",
            "value": 317072.54878235364,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 634147\nmean latency: 3 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [wasm]",
            "value": 21037.884291636394,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 42076\nmean latency: 48 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [wasm]",
            "value": 1460.2035786735294,
            "range": "±0.49%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2921\nmean latency: 685 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [wasm]",
            "value": 1310.7627519418986,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2622\nmean latency: 763 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [wasm]",
            "value": 20965.779859311475,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 41932\nmean latency: 48 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [wasm]",
            "value": 126.90964033608071,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 254\nmean latency: 7880 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [wasm]",
            "value": 119.92618543286608,
            "range": "±0.49%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 240\nmean latency: 8338 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [wasm]",
            "value": 19913.721207903087,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 39828\nmean latency: 50 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [wasm]",
            "value": 1443.6073388038453,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2888\nmean latency: 693 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [wasm]",
            "value": 432778.36300668895,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 865629\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [wasm]",
            "value": 5623.842532409092,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 11248\nmean latency: 178 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [wasm]",
            "value": 687.1141853849064,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1375\nmean latency: 1455 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [wasm]",
            "value": 4776.789821247865,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 9554\nmean latency: 209 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [wasm]",
            "value": 2559.10845640617,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 5119\nmean latency: 391 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [wasm]",
            "value": 1438763,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2877526\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [wasm]",
            "value": 148157,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 296314\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [wasm]",
            "value": 610509,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1221018\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [wasm]",
            "value": 19850.930521743176,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 39702\nmean latency: 50 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [wasm]",
            "value": 125.27563134426242,
            "range": "±0.55%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 251\nmean latency: 7982 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [wasm]",
            "value": 434104.56589543406,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 868210\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [wasm]",
            "value": 3493.923133691059,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 6988\nmean latency: 286 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [wasm]",
            "value": 62.46345887655721,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 125\nmean latency: 16009 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [wasm]",
            "value": 424.52262430896457,
            "range": "±0.65%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 850\nmean latency: 2356 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [wasm]",
            "value": 2482.9764117240884,
            "range": "±0.65%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4966\nmean latency: 403 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [wasm]",
            "value": 1447364,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2894728\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [wasm]",
            "value": 148261.35173864826,
            "range": "±0.55%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 296523\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [wasm]",
            "value": 606550,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1213100\nmean latency: 2 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 485.2716796747131,
            "range": "±0.63%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 971\nmean latency: 2061 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [wasm]",
            "value": 1275.5956361833298,
            "range": "±0.62%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2552\nmean latency: 784 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 1130.7845855364553,
            "range": "±0.58%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2262\nmean latency: 884 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 2186.38193537549,
            "range": "±0.67%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4373\nmean latency: 457 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [wasm]",
            "value": 21348.44662888343,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 42697\nmean latency: 47 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [wasm]",
            "value": 15882.07118407803,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 31765\nmean latency: 63 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [wasm]",
            "value": 250147.24985275016,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 500295\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [wasm]",
            "value": 31238.062667122656,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 62477\nmean latency: 32 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [wasm]",
            "value": 48345.40330919338,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 96691\nmean latency: 21 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [wasm]",
            "value": 21458.081567409434,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 42917\nmean latency: 47 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [wasm]",
            "value": 16013.527600935773,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32028\nmean latency: 62 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [wasm]",
            "value": 236285.00000000003,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 472570\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [wasm]",
            "value": 5616.2669249226155,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 11233\nmean latency: 178 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [wasm]",
            "value": 7291.445314160143,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14583\nmean latency: 137 microseconds"
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
          "id": "5803a6e5be348f61420e6383363e037e094fc37f",
          "message": "perf: serve cache queries from a sorted child index\n\nKeep each non-priority ordering on the write tree, and on the cached value when that node is complete, so a limited read is the window of that map. The persistence and master view benchmarks register that ordering before the timed call.\n\nCo-authored-by: Cursor <cursoragent@cursor.com>",
          "timestamp": "2026-11-11T14:48:32+01:00",
          "tree_id": "3268f0f5eace2ebfa4c74ad93fa3ba79558d1bf9",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/5803a6e5be348f61420e6383363e037e094fc37f"
        },
        "date": 1794435093970,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1360.859831437362,
            "range": "±2.15%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2722\nmean latency: 735 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 340.79058418601767,
            "range": "±0.65%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 682\nmean latency: 2934 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 402.35454883059776,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 805\nmean latency: 2485 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1915.0308174497247,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3831\nmean latency: 522 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 18330.151727117183,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 36661\nmean latency: 55 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 2862.984253586605,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5726\nmean latency: 349 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 7910.092630229543,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 15821\nmean latency: 126 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [jit]",
            "value": 52997.00000000001,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 105994\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [jit]",
            "value": 53095.920356119466,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 106192\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [jit]",
            "value": 44589.75475634884,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 89180\nmean latency: 22 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [jit]",
            "value": 93320.08005963973,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 186641\nmean latency: 11 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [jit]",
            "value": 3290190,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6580380\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [jit]",
            "value": 54057.86485533786,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 108116\nmean latency: 18 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [jit]",
            "value": 45853.61024431292,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 91708\nmean latency: 22 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [jit]",
            "value": 93418.35987246019,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 186837\nmean latency: 11 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [jit]",
            "value": 143441.92827903587,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 286884\nmean latency: 7 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [jit]",
            "value": 52255.63421056052,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 104512\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [jit]",
            "value": 52636.92104461843,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 105274\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [jit]",
            "value": 45253.79635791639,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 90508\nmean latency: 22 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [jit]",
            "value": 77801.03319380083,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 155603\nmean latency: 13 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [jit]",
            "value": 3342380.0000000005,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6684760\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [jit]",
            "value": 53139.78744085024,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 106280\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [jit]",
            "value": 45266.47736676132,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 90533\nmean latency: 22 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [jit]",
            "value": 70920.68085693615,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 141842\nmean latency: 14 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [jit]",
            "value": 109322.94533852732,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 218646\nmean latency: 9 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [jit]",
            "value": 52863.18282090307,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 105727\nmean latency: 19 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [jit]",
            "value": 44434.166743749425,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 88869\nmean latency: 23 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [jit]",
            "value": 19342.912956891694,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 38686\nmean latency: 52 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [jit]",
            "value": 52921.31477539829,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 105843\nmean latency: 19 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [jit]",
            "value": 44741.209182140316,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 89483\nmean latency: 22 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [jit]",
            "value": 18843.9717340424,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 37688\nmean latency: 53 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [jit]",
            "value": 48727.28072723673,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 97455\nmean latency: 21 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [jit]",
            "value": 41726.45827354173,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 83453\nmean latency: 24 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [jit]",
            "value": 585422.5,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1170845\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [jit]",
            "value": 12871.48712851287,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 25743\nmean latency: 78 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [jit]",
            "value": 11959.760804783904,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 23920\nmean latency: 84 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [jit]",
            "value": 8468.229016671467,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 16937\nmean latency: 118 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [jit]",
            "value": 5316.090661019101,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10633\nmean latency: 188 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [jit]",
            "value": 1899553.5,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3799107\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [jit]",
            "value": 260363,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 520726\nmean latency: 4 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [jit]",
            "value": 980232,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1960464\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [jit]",
            "value": 48977.706133763204,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 97956\nmean latency: 20 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [jit]",
            "value": 41715.39571151072,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 83431\nmean latency: 24 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [jit]",
            "value": 582848.2085758958,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1165697\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [jit]",
            "value": 12980.675483112922,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 25962\nmean latency: 77 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [jit]",
            "value": 11677.953288186847,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 23356\nmean latency: 86 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [jit]",
            "value": 815.4454970619979,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1632\nmean latency: 1226 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [jit]",
            "value": 5120.63387467796,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10242\nmean latency: 195 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [jit]",
            "value": 1837991.486025542,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3675994\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [jit]",
            "value": 265243.3673783163,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 530487\nmean latency: 4 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [jit]",
            "value": 979260.5,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1958521\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 957.560001179458,
            "range": "±0.84%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1916\nmean latency: 1044 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [jit]",
            "value": 2503.5468580186985,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5008\nmean latency: 399 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 2230.9107635694572,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4462\nmean latency: 448 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [jit]",
            "value": 4621.412193168329,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9243\nmean latency: 216 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [jit]",
            "value": 53424.25959083184,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 106849\nmean latency: 19 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [jit]",
            "value": 45474.295365670856,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 90949\nmean latency: 22 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [jit]",
            "value": 2958047.5,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5916095\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [jit]",
            "value": 103513.8964861035,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 207028\nmean latency: 10 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [jit]",
            "value": 177456.2338156493,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 354913\nmean latency: 6 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [jit]",
            "value": 53205.39358921282,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 106411\nmean latency: 19 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [jit]",
            "value": 45291.432062851905,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 90583\nmean latency: 22 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [jit]",
            "value": 2944126,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5888252\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [jit]",
            "value": 85402.87189569217,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 170806\nmean latency: 12 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [jit]",
            "value": 131150,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 262300\nmean latency: 8 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1608.298158581098,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3217\nmean latency: 622 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 366.820258073544,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 734\nmean latency: 2726 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 428.76289411955185,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 858\nmean latency: 2332 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1671.6464467765068,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3344\nmean latency: 598 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 16132.822538952072,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 32266\nmean latency: 62 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 2507.3984503627603,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5015\nmean latency: 399 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 7072.911588605142,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 14146\nmean latency: 141 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [aot]",
            "value": 39217.40195649511,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 78435\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [aot]",
            "value": 39944.20041849686,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 79889\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [aot]",
            "value": 34357.24232068259,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 68715\nmean latency: 29 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [aot]",
            "value": 75494.16027627875,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 150989\nmean latency: 13 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [aot]",
            "value": 3952615.5,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7905231\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [aot]",
            "value": 40888.85688900088,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 81778\nmean latency: 24 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [aot]",
            "value": 33857.17835680561,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 67715\nmean latency: 30 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [aot]",
            "value": 69261.93073806926,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 138524\nmean latency: 14 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [aot]",
            "value": 107447.62393331622,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 214896\nmean latency: 9 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [aot]",
            "value": 38695.806520967395,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 77392\nmean latency: 26 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [aot]",
            "value": 39258.18593451253,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 78517\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [aot]",
            "value": 32619.575945512708,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 65240\nmean latency: 31 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [aot]",
            "value": 59504.67272430002,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 119010\nmean latency: 17 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [aot]",
            "value": 3946216,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7892432\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [aot]",
            "value": 40015.69988225088,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 80032\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [aot]",
            "value": 34987.290076259545,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 69975\nmean latency: 29 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [aot]",
            "value": 52370.71196108421,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 104742\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [aot]",
            "value": 81482.5,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 162965\nmean latency: 12 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [aot]",
            "value": 39522.92095415809,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 79046\nmean latency: 25 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [aot]",
            "value": 33765.364938540246,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 67531\nmean latency: 30 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [aot]",
            "value": 16672.37495718782,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 33345\nmean latency: 60 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [aot]",
            "value": 39434.68452252382,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 78870\nmean latency: 25 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [aot]",
            "value": 33776.61156896695,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 67554\nmean latency: 30 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [aot]",
            "value": 15729.653947613153,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 31460\nmean latency: 64 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [aot]",
            "value": 38263.48086825957,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 76527\nmean latency: 26 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [aot]",
            "value": 32043.871824512702,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 64088\nmean latency: 31 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [aot]",
            "value": 680577,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1361154\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [aot]",
            "value": 11049.784529201681,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 22100\nmean latency: 90 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [aot]",
            "value": 9961.621458384581,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 19924\nmean latency: 100 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [aot]",
            "value": 8089.672368269085,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 16180\nmean latency: 124 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [aot]",
            "value": 4919.067122093256,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9839\nmean latency: 203 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [aot]",
            "value": 2211539,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4423078\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [aot]",
            "value": 321947.83902608044,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 643896\nmean latency: 3 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [aot]",
            "value": 1157274.5,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2314549\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [aot]",
            "value": 37400.53249334383,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 74802\nmean latency: 27 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [aot]",
            "value": 32215.113418638975,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 64431\nmean latency: 31 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [aot]",
            "value": 682459.5,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1364919\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [aot]",
            "value": 10549.593840637135,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 21100\nmean latency: 95 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [aot]",
            "value": 9609.778975083573,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 19220\nmean latency: 104 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [aot]",
            "value": 738.9279545244339,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1478\nmean latency: 1353 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [aot]",
            "value": 4750.435869115767,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9501\nmean latency: 211 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [aot]",
            "value": 2188152,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4376304\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [aot]",
            "value": 317539.82460175396,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 635086\nmean latency: 3 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [aot]",
            "value": 1134662.5,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2269325\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 1014.7934895248817,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2030\nmean latency: 985 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [aot]",
            "value": 2734.9001761435707,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5470\nmean latency: 366 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 2292.952994463614,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4586\nmean latency: 436 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [aot]",
            "value": 4671.121639147229,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9343\nmean latency: 214 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [aot]",
            "value": 40162.8192673133,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 80326\nmean latency: 25 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [aot]",
            "value": 35361.575661092065,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 70724\nmean latency: 28 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [aot]",
            "value": 3576594.5,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7153189\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [aot]",
            "value": 85710.91428908572,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 171422\nmean latency: 12 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [aot]",
            "value": 134500.52924814762,
            "range": "±0.12%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 269002\nmean latency: 7 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [aot]",
            "value": 40272.29863850681,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 80545\nmean latency: 25 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [aot]",
            "value": 34952.115526729205,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 69905\nmean latency: 29 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [aot]",
            "value": 3588666.4999999995,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7177333\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [aot]",
            "value": 67807.79657661027,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 135616\nmean latency: 15 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [aot]",
            "value": 98177,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 196354\nmean latency: 10 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 232.76723276723277,
            "range": "±2.63%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 466\nmean latency: 4296 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 78.96051974012993,
            "range": "±1.10%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 158\nmean latency: 12665 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 97.4512743628186,
            "range": "±1.72%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 195\nmean latency: 10262 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 112.21945137157107,
            "range": "±1.93%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 225\nmean latency: 8911 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2290.5,
            "range": "±3.30%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4581\nmean latency: 437 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 334,
            "range": "±1.03%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 668\nmean latency: 2994 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1039,
            "range": "±1.10%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2078\nmean latency: 962 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [js]",
            "value": 5227,
            "range": "±3.94%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10454\nmean latency: 191 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [js]",
            "value": 5292,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10584\nmean latency: 189 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [js]",
            "value": 4556.5,
            "range": "±3.87%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9113\nmean latency: 219 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [js]",
            "value": 6428.5,
            "range": "±4.03%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 12857\nmean latency: 156 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [js]",
            "value": 667046,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1334092\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [js]",
            "value": 5343,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10686\nmean latency: 187 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [js]",
            "value": 4638.5,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9277\nmean latency: 216 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [js]",
            "value": 9474.5,
            "range": "±4.15%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 18949\nmean latency: 106 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [js]",
            "value": 15302.5,
            "range": "±4.24%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 30605\nmean latency: 65 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [js]",
            "value": 5308,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10616\nmean latency: 188 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [js]",
            "value": 5310.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10621\nmean latency: 188 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [js]",
            "value": 4594,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9188\nmean latency: 218 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [js]",
            "value": 1866.9999999999998,
            "range": "±2.99%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3734\nmean latency: 536 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [js]",
            "value": 672342,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1344684\nmean latency: 1 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [js]",
            "value": 5365.5,
            "range": "±3.96%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10731\nmean latency: 186 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [js]",
            "value": 4655.5,
            "range": "±3.89%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9311\nmean latency: 215 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [js]",
            "value": 7233.5,
            "range": "±4.08%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14467\nmean latency: 138 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [js]",
            "value": 11551.5,
            "range": "±4.19%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 23103\nmean latency: 87 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [js]",
            "value": 5287.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10575\nmean latency: 189 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [js]",
            "value": 4624,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9248\nmean latency: 216 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [js]",
            "value": 1963.5,
            "range": "±3.08%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3927\nmean latency: 509 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [js]",
            "value": 5276,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10552\nmean latency: 190 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [js]",
            "value": 4586.5,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9173\nmean latency: 218 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [js]",
            "value": 1096,
            "range": "±1.42%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2192\nmean latency: 912 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [js]",
            "value": 4859,
            "range": "±3.91%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9718\nmean latency: 206 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [js]",
            "value": 4326.5,
            "range": "±3.84%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 8653\nmean latency: 231 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [js]",
            "value": 123924.50000000001,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 247849\nmean latency: 8 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [js]",
            "value": 1250,
            "range": "±2.06%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2500\nmean latency: 800 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [js]",
            "value": 1185,
            "range": "±1.86%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2370\nmean latency: 844 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [js]",
            "value": 945,
            "range": "±1.06%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1890\nmean latency: 1058 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [js]",
            "value": 635.1824087956022,
            "range": "±1.78%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1271\nmean latency: 1574 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [js]",
            "value": 212156.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 424313\nmean latency: 5 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [js]",
            "value": 43777.5,
            "range": "±4.33%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 87555\nmean latency: 23 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [js]",
            "value": 140734,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 281468\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [js]",
            "value": 5009.5,
            "range": "±3.92%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10019\nmean latency: 200 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [js]",
            "value": 4386,
            "range": "±3.85%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 8772\nmean latency: 228 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [js]",
            "value": 123588.5,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 247177\nmean latency: 8 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [js]",
            "value": 844,
            "range": "±1.58%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1688\nmean latency: 1185 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [js]",
            "value": 821,
            "range": "±1.64%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1642\nmean latency: 1218 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [js]",
            "value": 100.44977511244377,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 201\nmean latency: 9955 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [js]",
            "value": 617.5,
            "range": "±1.69%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1235\nmean latency: 1619 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [js]",
            "value": 213845.5,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 427691\nmean latency: 5 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [js]",
            "value": 43853,
            "range": "±4.33%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 87706\nmean latency: 23 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [js]",
            "value": 141609.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 283219\nmean latency: 7 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 139,
            "range": "±1.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 278\nmean latency: 7194 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [js]",
            "value": 368.6313686313686,
            "range": "±1.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 738\nmean latency: 2713 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 315,
            "range": "±0.96%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 630\nmean latency: 3175 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [js]",
            "value": 679,
            "range": "±1.82%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1358\nmean latency: 1473 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [js]",
            "value": 5260,
            "range": "±3.94%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10520\nmean latency: 190 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [js]",
            "value": 4612.5,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9225\nmean latency: 217 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [js]",
            "value": 79518,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 159036\nmean latency: 13 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [js]",
            "value": 6984,
            "range": "±4.06%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 13968\nmean latency: 143 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [js]",
            "value": 10512.5,
            "range": "±4.17%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 21025\nmean latency: 95 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [js]",
            "value": 5340.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10681\nmean latency: 187 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [js]",
            "value": 4637,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9274\nmean latency: 216 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [js]",
            "value": 78304.5,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 156609\nmean latency: 13 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [js]",
            "value": 1842,
            "range": "±2.97%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3684\nmean latency: 543 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [js]",
            "value": 2102,
            "range": "±3.19%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4204\nmean latency: 476 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 634.8260576602012,
            "range": "±1.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1270\nmean latency: 1575 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 155.75771886830034,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 312\nmean latency: 6420 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 197.46080403039997,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 395\nmean latency: 5064 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 490.4418826369075,
            "range": "±0.57%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 981\nmean latency: 2039 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 8337.837412170464,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 16676\nmean latency: 120 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 1375.3762161405475,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2751\nmean latency: 727 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 4099.317580367674,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8199\nmean latency: 244 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [wasm]",
            "value": 21645.740251116986,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43292\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [wasm]",
            "value": 21803.792863967792,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43608\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [wasm]",
            "value": 16228.910740990925,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32458\nmean latency: 62 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [wasm]",
            "value": 29409.6029703599,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 58820\nmean latency: 34 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [wasm]",
            "value": 4449585.652968424,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8899772\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [wasm]",
            "value": 22087.834341242444,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 44176\nmean latency: 45 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [wasm]",
            "value": 16536.776753513826,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 33074\nmean latency: 60 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [wasm]",
            "value": 39550.822021300904,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 79102\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [wasm]",
            "value": 66365.2013565939,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 132731\nmean latency: 15 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [wasm]",
            "value": 21722.130723777696,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43445\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [wasm]",
            "value": 21831.172532412016,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43663\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [wasm]",
            "value": 16284.158032681315,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32569\nmean latency: 61 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [wasm]",
            "value": 6587.950590370572,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 13176\nmean latency: 152 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [wasm]",
            "value": 4470227,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8940454\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [wasm]",
            "value": 22132.679076153396,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 44266\nmean latency: 45 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [wasm]",
            "value": 16248.97562653656,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32498\nmean latency: 62 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [wasm]",
            "value": 29909.275680432394,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 59819\nmean latency: 33 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [wasm]",
            "value": 50745.06866691633,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 101491\nmean latency: 20 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [wasm]",
            "value": 21923.225959675503,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43847\nmean latency: 46 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [wasm]",
            "value": 16375.278933734395,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32751\nmean latency: 61 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [wasm]",
            "value": 7429.184259668964,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14859\nmean latency: 135 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [wasm]",
            "value": 21666.599167915396,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43334\nmean latency: 46 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [wasm]",
            "value": 16007.719864902363,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32016\nmean latency: 62 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [wasm]",
            "value": 4150.143087694458,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8301\nmean latency: 241 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [wasm]",
            "value": 20470.877174736954,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 40942\nmean latency: 49 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [wasm]",
            "value": 15398.168939367804,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 30797\nmean latency: 65 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [wasm]",
            "value": 421320.2893398553,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 842641\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [wasm]",
            "value": 5217.882597641554,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 10436\nmean latency: 192 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [wasm]",
            "value": 4403.130137068486,
            "range": "±0.48%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8807\nmean latency: 227 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [wasm]",
            "value": 4117.656175709328,
            "range": "±0.42%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8236\nmean latency: 243 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [wasm]",
            "value": 2652.4628655198826,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 5305\nmean latency: 377 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [wasm]",
            "value": 1502095,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3004190\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [wasm]",
            "value": 151306,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 302612\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [wasm]",
            "value": 646265.5,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1292531\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [wasm]",
            "value": 20330.583223043926,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 40662\nmean latency: 49 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [wasm]",
            "value": 15306.811193496293,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 30615\nmean latency: 65 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [wasm]",
            "value": 418962,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 837924\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [wasm]",
            "value": 3265.929782509676,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 6532\nmean latency: 306 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [wasm]",
            "value": 2910.3806743923496,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 5821\nmean latency: 344 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [wasm]",
            "value": 413.3542926118543,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 827\nmean latency: 2419 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [wasm]",
            "value": 2495.241742479653,
            "range": "±0.58%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4991\nmean latency: 401 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [wasm]",
            "value": 1507886.5,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3015773\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [wasm]",
            "value": 150858.34914165086,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 301717\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [wasm]",
            "value": 640946.5,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1281893\nmean latency: 2 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 493.97085571951254,
            "range": "±0.59%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 988\nmean latency: 2024 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [wasm]",
            "value": 1304.0383704168723,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2609\nmean latency: 767 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 1174.3602511301156,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2349\nmean latency: 852 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 2200.354776584745,
            "range": "±0.57%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4401\nmean latency: 454 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [wasm]",
            "value": 22104.12422988809,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 44209\nmean latency: 45 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [wasm]",
            "value": 16353.230171702167,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32707\nmean latency: 61 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [wasm]",
            "value": 253737.87313106345,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 507476\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [wasm]",
            "value": 32777.80333318,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 65556\nmean latency: 31 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [wasm]",
            "value": 46217.13026295789,
            "range": "±0.88%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 92435\nmean latency: 22 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [wasm]",
            "value": 21672.304949255456,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43345\nmean latency: 46 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [wasm]",
            "value": 16374.557886937053,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32750\nmean latency: 61 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [wasm]",
            "value": 244733.143433998,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 489468\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [wasm]",
            "value": 6663.100213987161,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 13327\nmean latency: 150 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [wasm]",
            "value": 7620.431416117255,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 15241\nmean latency: 131 microseconds"
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
          "id": "5f1015441aea1dddf33c59857c1af7a8d7576f2f",
          "message": "perf: use the query index when updating the server cache\n\nAn order-by update sorted every child to read the page and again to check the result. Register the ordering first so both reads are a window of the sorted map.\n\nCo-authored-by: Cursor <cursoragent@cursor.com>",
          "timestamp": "2026-11-11T14:48:33+01:00",
          "tree_id": "8667d6029fdaf8c3f3de60180196fabac09b244f",
          "url": "https://github.com/appsup-dart/firebase_dart/commit/5f1015441aea1dddf33c59857c1af7a8d7576f2f"
        },
        "date": 1794436009975,
        "tool": "customBiggerIsBetter",
        "benches": [
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [jit]",
            "value": 1381.3004020918977,
            "range": "±2.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 2763\nmean latency: 724 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [jit]",
            "value": 344.3295568693497,
            "range": "±0.74%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 689\nmean latency: 2904 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [jit]",
            "value": 393.8198274289512,
            "range": "±0.51%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 788\nmean latency: 2539 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [jit]",
            "value": 1760.997358503962,
            "range": "±0.59%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3522\nmean latency: 568 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [jit]",
            "value": 19244.02852130123,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 38489\nmean latency: 52 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [jit]",
            "value": 2827.7978124564092,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5656\nmean latency: 354 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [jit]",
            "value": 7658.243448844464,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 15317\nmean latency: 131 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [jit]",
            "value": 52202.395595208814,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 104405\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [jit]",
            "value": 52345.764444060005,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 104692\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [jit]",
            "value": 42804.78597607012,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 85610\nmean latency: 23 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [jit]",
            "value": 91484.90851509149,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 182970\nmean latency: 11 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [jit]",
            "value": 3328069.5,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6656139\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [jit]",
            "value": 52754.81535814625,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 105510\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [jit]",
            "value": 44175.47791226105,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 88351\nmean latency: 23 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [jit]",
            "value": 92015.2699618251,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 184031\nmean latency: 11 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [jit]",
            "value": 145877.5623673129,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 291756\nmean latency: 7 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [jit]",
            "value": 51698.42245236632,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 103397\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [jit]",
            "value": 51564.31952488166,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 103129\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [jit]",
            "value": 44864.61865074147,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 89730\nmean latency: 22 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [jit]",
            "value": 75708.15931328309,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 151417\nmean latency: 13 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [jit]",
            "value": 3358123,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 6716246\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [jit]",
            "value": 51939.058518002596,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 103879\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [jit]",
            "value": 44903.09587213715,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 89807\nmean latency: 22 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [jit]",
            "value": 71064.07361555831,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 142129\nmean latency: 14 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [jit]",
            "value": 109341.67197498408,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 218684\nmean latency: 9 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [jit]",
            "value": 51362.08910328717,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 102725\nmean latency: 19 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [jit]",
            "value": 44060.55939440605,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 88122\nmean latency: 23 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [jit]",
            "value": 18720.35959730302,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 37441\nmean latency: 53 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [jit]",
            "value": 51808.689147865116,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 103618\nmean latency: 19 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [jit]",
            "value": 44245.12391644671,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 88491\nmean latency: 23 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [jit]",
            "value": 18285.207436681012,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 36571\nmean latency: 55 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [jit]",
            "value": 47663.95233604766,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 95328\nmean latency: 21 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [jit]",
            "value": 41174.8353006588,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 82350\nmean latency: 24 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [jit]",
            "value": 588444.2057778972,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1176889\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [jit]",
            "value": 12498.181296376943,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 24997\nmean latency: 80 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [jit]",
            "value": 11376.346419323338,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 22753\nmean latency: 88 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [jit]",
            "value": 8403.344538126044,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 16807\nmean latency: 119 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [jit]",
            "value": 5187.719863127391,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10376\nmean latency: 193 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [jit]",
            "value": 1839628.5,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3679257\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [jit]",
            "value": 260838.3695808152,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 521677\nmean latency: 4 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [jit]",
            "value": 961821.9999999999,
            "range": "±0.69%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1923644\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [jit]",
            "value": 48180.78318647566,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 96362\nmean latency: 21 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [jit]",
            "value": 41256.5,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 82513\nmean latency: 24 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [jit]",
            "value": 586742.7066286467,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1173486\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [jit]",
            "value": 12536.23673902848,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 25073\nmean latency: 80 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [jit]",
            "value": 11224.123991846272,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 22449\nmean latency: 89 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [jit]",
            "value": 786.206351927555,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1573\nmean latency: 1272 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [jit]",
            "value": 5062.069724073454,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 10125\nmean latency: 198 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [jit]",
            "value": 1847959.5000000002,
            "range": "±1.08%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 3695919\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [jit]",
            "value": 262951.5,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 525903\nmean latency: 4 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [jit]",
            "value": 984306.5,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1968613\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [jit]",
            "value": 970.9228116364749,
            "range": "±0.89%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 1942\nmean latency: 1030 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [jit]",
            "value": 2597.7428234604777,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5196\nmean latency: 385 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [jit]",
            "value": 2064.580890079314,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 4130\nmean latency: 484 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [jit]",
            "value": 4630.671222343214,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 9262\nmean latency: 216 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [jit]",
            "value": 50686.56916416211,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 101374\nmean latency: 20 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [jit]",
            "value": 45008.31996672013,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 90017\nmean latency: 22 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [jit]",
            "value": 2881192,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5762384\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [jit]",
            "value": 103695.34445698331,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 207391\nmean latency: 10 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [jit]",
            "value": 173378.8266211734,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 346758\nmean latency: 6 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [jit]",
            "value": 50112.2243827659,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 100225\nmean latency: 20 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [jit]",
            "value": 44851.163616272876,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 89703\nmean latency: 22 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [jit]",
            "value": 2874744.5,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 5749489\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [jit]",
            "value": 83406.24978125066,
            "range": "±0.93%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 166813\nmean latency: 12 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [jit]",
            "value": 128600.3713996286,
            "range": "±0.58%",
            "unit": "ops/sec",
            "extra": "compile: jit\nsamples: 257201\nmean latency: 8 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [aot]",
            "value": 1584.897774093571,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3170\nmean latency: 631 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [aot]",
            "value": 365.4015242892041,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 731\nmean latency: 2737 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [aot]",
            "value": 421.70754581697594,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 844\nmean latency: 2371 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [aot]",
            "value": 1667.7848557536076,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 3336\nmean latency: 600 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [aot]",
            "value": 15950.165046534023,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 31901\nmean latency: 63 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [aot]",
            "value": 2500.7511752580617,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5002\nmean latency: 400 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [aot]",
            "value": 6960.581203281166,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 13923\nmean latency: 144 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [aot]",
            "value": 39360.126078802256,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 78721\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [aot]",
            "value": 38955.66887681455,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 77912\nmean latency: 26 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [aot]",
            "value": 33808.09430286837,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 67617\nmean latency: 30 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [aot]",
            "value": 75590.69763720945,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 151182\nmean latency: 13 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [aot]",
            "value": 3936831,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7873662\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [aot]",
            "value": 40981.110679448546,
            "range": "±0.21%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 81963\nmean latency: 24 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [aot]",
            "value": 34299.15700842992,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 68599\nmean latency: 29 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [aot]",
            "value": 70255.89461615807,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 140512\nmean latency: 14 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [aot]",
            "value": 109465.89053410947,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 218932\nmean latency: 9 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [aot]",
            "value": 39564.782393696834,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 79130\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [aot]",
            "value": 39363.342546629814,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 78727\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [aot]",
            "value": 33918.96608103392,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 67838\nmean latency: 29 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [aot]",
            "value": 60961.90855713716,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 121924\nmean latency: 16 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [aot]",
            "value": 3961912.5000000005,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7923825\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [aot]",
            "value": 40268.59731402686,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 80538\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [aot]",
            "value": 34354.707984982124,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 68710\nmean latency: 29 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [aot]",
            "value": 53438.366404083994,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 106877\nmean latency: 19 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [aot]",
            "value": 82077.54857348284,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 164156\nmean latency: 12 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [aot]",
            "value": 39506.420987158024,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 79013\nmean latency: 25 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [aot]",
            "value": 34106.89767930696,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 68214\nmean latency: 29 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [aot]",
            "value": 16845.528325206895,
            "range": "±0.18%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 33692\nmean latency: 59 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [aot]",
            "value": 40104.21927046511,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 80209\nmean latency: 25 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [aot]",
            "value": 34025.006637403756,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 68051\nmean latency: 29 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [aot]",
            "value": 15964.364302903427,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 31929\nmean latency: 63 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [aot]",
            "value": 37471.831376758804,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 74944\nmean latency: 27 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [aot]",
            "value": 32507.04490137138,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 65015\nmean latency: 31 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [aot]",
            "value": 692646,
            "range": "±0.14%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1385292\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [aot]",
            "value": 11081.3337799933,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 22163\nmean latency: 90 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [aot]",
            "value": 10057.984143601496,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 20118\nmean latency: 99 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [aot]",
            "value": 8076.733467795562,
            "range": "±0.17%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 16154\nmean latency: 124 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [aot]",
            "value": 4972.189238172614,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9945\nmean latency: 201 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [aot]",
            "value": 2173926.5,
            "range": "±0.13%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4347853\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [aot]",
            "value": 318665.34066732967,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 637331\nmean latency: 3 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [aot]",
            "value": 1160052.5,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2320105\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [aot]",
            "value": 37504.643705884795,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 75010\nmean latency: 27 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [aot]",
            "value": 32348.030953551173,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 64697\nmean latency: 31 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [aot]",
            "value": 690009.5,
            "range": "±0.23%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1380019\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [aot]",
            "value": 10636.797900839885,
            "range": "±0.22%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 21274\nmean latency: 94 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [aot]",
            "value": 9603.269521531483,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 19207\nmean latency: 104 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [aot]",
            "value": 736.9115706115267,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 1474\nmean latency: 1357 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [aot]",
            "value": 4769.830671011179,
            "range": "±0.27%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9540\nmean latency: 210 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [aot]",
            "value": 2149408.5,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4298817\nmean latency: 0 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [aot]",
            "value": 316989.5,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 633979\nmean latency: 3 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [aot]",
            "value": 1151147.5,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2302295\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [aot]",
            "value": 1034.069826951988,
            "range": "±0.44%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 2069\nmean latency: 967 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [aot]",
            "value": 2693.708049833349,
            "range": "±0.25%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 5389\nmean latency: 371 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [aot]",
            "value": 2229.405250276863,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 4459\nmean latency: 449 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [aot]",
            "value": 4800.9591918468695,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 9602\nmean latency: 208 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [aot]",
            "value": 40132.4398013403,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 80265\nmean latency: 25 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [aot]",
            "value": 35554.35778256887,
            "range": "±0.15%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 71109\nmean latency: 28 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [aot]",
            "value": 3583677.0000000005,
            "range": "±0.19%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7167354\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [aot]",
            "value": 85992.15603137588,
            "range": "±0.16%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 171985\nmean latency: 12 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [aot]",
            "value": 135971.5,
            "range": "±0.11%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 271943\nmean latency: 7 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [aot]",
            "value": 40280.81873631568,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 80562\nmean latency: 25 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [aot]",
            "value": 35169.92966014068,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 70340\nmean latency: 28 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [aot]",
            "value": 3581150,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 7162300\nmean latency: 0 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [aot]",
            "value": 67831.83042042395,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 135664\nmean latency: 15 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [aot]",
            "value": 98732.60506957972,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: aot\nsamples: 197466\nmean latency: 10 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [js]",
            "value": 225,
            "range": "±2.56%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 450\nmean latency: 4444 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [js]",
            "value": 76.5,
            "range": "±1.27%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 153\nmean latency: 13072 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [js]",
            "value": 95.76059850374064,
            "range": "±1.00%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 192\nmean latency: 10443 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [js]",
            "value": 109.28143712574851,
            "range": "±1.62%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 219\nmean latency: 9151 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [js]",
            "value": 2328.5,
            "range": "±3.31%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4657\nmean latency: 429 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [js]",
            "value": 332.16783216783216,
            "range": "±0.99%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 665\nmean latency: 3011 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [js]",
            "value": 1040.5,
            "range": "±1.03%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2081\nmean latency: 961 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [js]",
            "value": 5198.5,
            "range": "±3.94%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10397\nmean latency: 192 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [js]",
            "value": 5306.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10613\nmean latency: 188 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [js]",
            "value": 4606,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9212\nmean latency: 217 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [js]",
            "value": 6431,
            "range": "±4.03%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 12862\nmean latency: 155 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [js]",
            "value": 640527,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1281054\nmean latency: 2 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [js]",
            "value": 5357.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10715\nmean latency: 187 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [js]",
            "value": 4666,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9332\nmean latency: 214 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [js]",
            "value": 9423,
            "range": "±4.14%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 18846\nmean latency: 106 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [js]",
            "value": 15171.999999999998,
            "range": "±4.24%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 30344\nmean latency: 66 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [js]",
            "value": 5324.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10649\nmean latency: 188 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [js]",
            "value": 5290,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10580\nmean latency: 189 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [js]",
            "value": 4649,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9298\nmean latency: 215 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [js]",
            "value": 1802.4999999999998,
            "range": "±2.93%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3605\nmean latency: 555 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [js]",
            "value": 630330.5,
            "range": "±4.38%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1260661\nmean latency: 2 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [js]",
            "value": 5349.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10699\nmean latency: 187 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [js]",
            "value": 4668.5,
            "range": "±3.89%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9337\nmean latency: 214 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [js]",
            "value": 7257.999999999999,
            "range": "±4.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14516\nmean latency: 138 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [js]",
            "value": 11640.000000000002,
            "range": "±4.20%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 23280\nmean latency: 86 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [js]",
            "value": 5306,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10612\nmean latency: 188 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [js]",
            "value": 4648,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9296\nmean latency: 215 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [js]",
            "value": 1951.9999999999998,
            "range": "±3.07%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3904\nmean latency: 512 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [js]",
            "value": 5313.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10627\nmean latency: 188 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [js]",
            "value": 4607,
            "range": "±3.88%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9214\nmean latency: 217 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [js]",
            "value": 1128.5,
            "range": "±1.60%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2257\nmean latency: 886 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [js]",
            "value": 4958.5,
            "range": "±3.92%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9917\nmean latency: 202 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [js]",
            "value": 4404.5,
            "range": "±3.85%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 8809\nmean latency: 227 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [js]",
            "value": 120790.49999999999,
            "range": "±4.36%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 241581\nmean latency: 8 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [js]",
            "value": 1242.5,
            "range": "±2.05%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2485\nmean latency: 805 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [js]",
            "value": 1178.5,
            "range": "±1.79%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 2357\nmean latency: 849 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [js]",
            "value": 944.5,
            "range": "±1.00%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1889\nmean latency: 1059 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [js]",
            "value": 577.2113943028486,
            "range": "±1.59%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1155\nmean latency: 1732 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [js]",
            "value": 213099,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 426198\nmean latency: 5 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [js]",
            "value": 43609,
            "range": "±4.33%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 87218\nmean latency: 23 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [js]",
            "value": 142725,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 285450\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [js]",
            "value": 5069.5,
            "range": "±3.93%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10139\nmean latency: 197 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [js]",
            "value": 4437,
            "range": "±3.86%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 8874\nmean latency: 225 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [js]",
            "value": 119526,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 239052\nmean latency: 8 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [js]",
            "value": 844,
            "range": "±1.56%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1688\nmean latency: 1185 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [js]",
            "value": 804.5,
            "range": "±1.69%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1609\nmean latency: 1243 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [js]",
            "value": 96.45177411294353,
            "range": "±0.82%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 193\nmean latency: 10368 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [js]",
            "value": 575.5,
            "range": "±1.47%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1151\nmean latency: 1738 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [js]",
            "value": 213971.49999999997,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 427943\nmean latency: 5 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [js]",
            "value": 43913,
            "range": "±4.34%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 87826\nmean latency: 23 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [js]",
            "value": 142055.5,
            "range": "±4.37%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 284111\nmean latency: 7 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [js]",
            "value": 138,
            "range": "±2.18%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 276\nmean latency: 7246 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [js]",
            "value": 362.3188405797101,
            "range": "±1.48%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 725\nmean latency: 2760 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [js]",
            "value": 316.1838161838162,
            "range": "±1.03%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 633\nmean latency: 3163 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [js]",
            "value": 717,
            "range": "±1.83%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 1434\nmean latency: 1395 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [js]",
            "value": 5378.5,
            "range": "±3.95%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10757\nmean latency: 186 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [js]",
            "value": 4747,
            "range": "±3.89%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9494\nmean latency: 211 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [js]",
            "value": 78440,
            "range": "±4.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 156880\nmean latency: 13 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [js]",
            "value": 7092,
            "range": "±4.06%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 14184\nmean latency: 141 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [js]",
            "value": 10815,
            "range": "±4.18%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 21630\nmean latency: 92 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [js]",
            "value": 5468.5,
            "range": "±3.96%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 10937\nmean latency: 183 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [js]",
            "value": 4744,
            "range": "±3.90%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 9488\nmean latency: 211 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [js]",
            "value": 78915,
            "range": "±4.35%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 157830\nmean latency: 13 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [js]",
            "value": 1838,
            "range": "±2.97%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 3676\nmean latency: 544 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [js]",
            "value": 2055,
            "range": "±3.14%",
            "unit": "ops/sec",
            "extra": "compile: js\nsamples: 4110\nmean latency: 487 microseconds"
          },
          {
            "name": "Calendar queries density: 5 events/day listen acks + first server snapshots [wasm]",
            "value": 591.8774813613583,
            "range": "±1.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1184\nmean latency: 1690 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event/day listen acks + first server snapshots [wasm]",
            "value": 152.87922541192458,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 306\nmean latency: 6541 microseconds"
          },
          {
            "name": "Calendar queries density: 1 event / 10 days listen acks + first server snapshots [wasm]",
            "value": 192.30961348265217,
            "range": "±0.55%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 385\nmean latency: 5200 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete root merge) [wasm]",
            "value": 488.59300202930956,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 978\nmean latency: 2047 microseconds"
          },
          {
            "name": "IncompleteData merge applyOperation (complete identity merge) [wasm]",
            "value": 8771.039520425178,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 17543\nmean latency: 114 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse merge) [wasm]",
            "value": 1373.3461852272544,
            "range": "±0.48%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2747\nmean latency: 728 microseconds"
          },
          {
            "name": "IncompleteData merge non-complete (per-overwrite loop) applyOperation (sparse identity merge) [wasm]",
            "value": 4069.7680232226767,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8140\nmean latency: 246 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter (same ordering) [wasm]",
            "value": 21634.164670447608,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43269\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (same ordering) [wasm]",
            "value": 21576.21950914638,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43153\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete withFilter + value (orderBy child) [wasm]",
            "value": 15973.94409119568,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 31948\nmean latency: 63 microseconds"
          },
          {
            "name": "IncompleteData 100 children complete applyOperation (one child) [wasm]",
            "value": 29245.23679286886,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 58491\nmean latency: 34 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter (same ordering) [wasm]",
            "value": 4339646,
            "range": "±0.29%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8679292\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (same ordering) [wasm]",
            "value": 22071.977928022072,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 44144\nmean latency: 45 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial withFilter + value (orderBy child) [wasm]",
            "value": 16258.21548122908,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32517\nmean latency: 62 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial applyOperation (one child) [wasm]",
            "value": 39300.106998930016,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 78601\nmean latency: 25 microseconds"
          },
          {
            "name": "IncompleteData 100 children partial removeWrite (one child) [wasm]",
            "value": 66251.16874415628,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 132503\nmean latency: 15 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter (same ordering) [wasm]",
            "value": 21636.099732154955,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43273\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (same ordering) [wasm]",
            "value": 21615.197387236578,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43231\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete withFilter + value (orderBy child) [wasm]",
            "value": 15997.08407581403,
            "range": "±0.40%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 31995\nmean latency: 63 microseconds"
          },
          {
            "name": "IncompleteData 1000 children complete applyOperation (one child) [wasm]",
            "value": 6165.663971313564,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 12332\nmean latency: 162 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter (same ordering) [wasm]",
            "value": 4304086.5,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8608173\nmean latency: 0 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (same ordering) [wasm]",
            "value": 21822.629015306742,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43646\nmean latency: 46 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial withFilter + value (orderBy child) [wasm]",
            "value": 16038.395750427622,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32077\nmean latency: 62 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial applyOperation (one child) [wasm]",
            "value": 29879.581685856396,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 59760\nmean latency: 33 microseconds"
          },
          {
            "name": "IncompleteData 1000 children partial removeWrite (one child) [wasm]",
            "value": 49840.07635935095,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 99681\nmean latency: 20 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page) [wasm]",
            "value": 21638.967541548685,
            "range": "±0.36%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 43278\nmean latency: 46 microseconds"
          },
          {
            "name": "MasterView 100 children valueForFilter (limited page, orderBy child) [wasm]",
            "value": 15974.544725475324,
            "range": "±0.39%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 31950\nmean latency: 63 microseconds"
          },
          {
            "name": "MasterView 100 children server update (one child, orderBy observer) [wasm]",
            "value": 7198.971204115183,
            "range": "±0.46%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14398\nmean latency: 139 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page) [wasm]",
            "value": 21379.64723582061,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 42760\nmean latency: 47 microseconds"
          },
          {
            "name": "MasterView 1000 children valueForFilter (limited page, orderBy child) [wasm]",
            "value": 15925.81685310619,
            "range": "±0.37%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 31852\nmean latency: 63 microseconds"
          },
          {
            "name": "MasterView 1000 children server update (one child, orderBy observer) [wasm]",
            "value": 4602.875722355496,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 9206\nmean latency: 217 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page) [wasm]",
            "value": 20353.69469457958,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 40708\nmean latency: 49 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (limited page, orderBy child) [wasm]",
            "value": 15149.045528634142,
            "range": "±0.41%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 30299\nmean latency: 66 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children serverCache (whole node, cached value) [wasm]",
            "value": 427833.286083357,
            "range": "±0.33%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 855667\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited, one child) [wasm]",
            "value": 5108.405494498352,
            "range": "±0.47%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 10217\nmean latency: 196 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited orderBy, one child) [wasm]",
            "value": 4263.32520366665,
            "range": "±0.52%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8527\nmean latency: 235 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (whole node, one child) [wasm]",
            "value": 4080.4673562611497,
            "range": "±0.45%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 8161\nmean latency: 245 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children updateServerCache (limited page overwrite) replaces the stored page [wasm]",
            "value": 2577.18558335883,
            "range": "±0.50%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 5155\nmean latency: 388 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children saveUserOperation + removeUserOperation [wasm]",
            "value": 1530047.5,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3060095\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryActive + setQueryInactive [wasm]",
            "value": 150864.1228396929,
            "range": "±0.24%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 301729\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 100 children setQueryComplete [wasm]",
            "value": 650041.5,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1300083\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page) [wasm]",
            "value": 20011.66980744818,
            "range": "±0.58%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 40024\nmean latency: 50 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (limited page, orderBy child) [wasm]",
            "value": 14980.14047662856,
            "range": "±0.55%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 29961\nmean latency: 67 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children serverCache (whole node, cached value) [wasm]",
            "value": 426273.5737264263,
            "range": "±0.48%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 852548\nmean latency: 2 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited, one child) [wasm]",
            "value": 2982.570509846582,
            "range": "±0.64%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 5966\nmean latency: 335 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited orderBy, one child) [wasm]",
            "value": 2853.10484497897,
            "range": "±0.60%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 5707\nmean latency: 350 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (whole node, one child) [wasm]",
            "value": 422.330856491975,
            "range": "±0.59%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 845\nmean latency: 2368 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children updateServerCache (limited page overwrite) replaces the stored page [wasm]",
            "value": 2483.2128215355733,
            "range": "±0.59%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4968\nmean latency: 403 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children saveUserOperation + removeUserOperation [wasm]",
            "value": 1531866.4999999998,
            "range": "±0.38%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 3063733\nmean latency: 1 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryActive + setQueryInactive [wasm]",
            "value": 152416.9237915381,
            "range": "±0.32%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 304834\nmean latency: 7 microseconds"
          },
          {
            "name": "DefaultPersistenceManager 1000 children setQueryComplete [wasm]",
            "value": 668945.5,
            "range": "±0.20%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1337891\nmean latency: 1 microseconds"
          },
          {
            "name": "SyncTree merge write path fullWriteCycle (merge + server + ack) [wasm]",
            "value": 502.9067108051456,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 1006\nmean latency: 1988 microseconds"
          },
          {
            "name": "SyncTree merge write path userMerge only [wasm]",
            "value": 1319.1220715265076,
            "range": "±0.53%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2639\nmean latency: 758 microseconds"
          },
          {
            "name": "SyncTree merge serverMerge only (after user merge) serverMerge [wasm]",
            "value": 1181.802638959294,
            "range": "±0.57%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 2364\nmean latency: 846 microseconds"
          },
          {
            "name": "SyncTree merge ack only (after user merge + server merge) ack [wasm]",
            "value": 2210.1242788725917,
            "range": "±0.54%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 4421\nmean latency: 452 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (same ordering) [wasm]",
            "value": 20797.177643746523,
            "range": "±0.43%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 41595\nmean latency: 48 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withFilter (orderBy child) [wasm]",
            "value": 16064.202812247973,
            "range": "±0.34%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32129\nmean latency: 62 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node view (same ordering) [wasm]",
            "value": 249519.12572131143,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 499039\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withChild [wasm]",
            "value": 30293.909118272648,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 60588\nmean latency: 33 microseconds"
          },
          {
            "name": "TreeStructuredData 100 children node withoutChild [wasm]",
            "value": 46863.648522636075,
            "range": "±0.30%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 93728\nmean latency: 21 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (same ordering) [wasm]",
            "value": 22108.922618770834,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 44218\nmean latency: 45 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withFilter (orderBy child) [wasm]",
            "value": 16236.788921744017,
            "range": "±0.35%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 32474\nmean latency: 62 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node view (same ordering) [wasm]",
            "value": 250024,
            "range": "±0.31%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 500048\nmean latency: 4 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withChild [wasm]",
            "value": 6747.287460444996,
            "range": "±0.28%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 13495\nmean latency: 148 microseconds"
          },
          {
            "name": "TreeStructuredData 1000 children node withoutChild [wasm]",
            "value": 7330.089514987161,
            "range": "±0.26%",
            "unit": "ops/sec",
            "extra": "compile: wasm\nsamples: 14661\nmean latency: 136 microseconds"
          }
        ]
      }
    ]
  }
}