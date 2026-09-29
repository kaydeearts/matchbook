# matchbook

A concurrent **electronic-exchange matching engine** in Swift — a server that holds an
**order book** and matches buy/sell orders by **price-time priority**, accessed concurrently
by many trader clients over TCP.

> **Status:** 🚧 in progress.

## Design

```
  trader client ─┐
  trader client ─┼── TCP (Network.framework) ──▶  matchbook server ──▶ MatchingEngine (actor)
  trader client ─┘                                                        └─ order book (bids/asks)
```

- **`MatchingEngine`** — pure order book + matching logic. No I/O, fully testable.
- **`matchbook`** — the server / driver executable.

A modern-stack revival of a Systems Architecture II project originally written in C
(pthreads, locks, semaphores) — rebuilt around Swift actors for compile-time data-race
safety and Network.framework for the networking.

## Build & run

```sh
swift build
swift test
swift run matchbook
```

## Roadmap

**Phase 1 — Matching engine core** *(nearly done)*
- [x] Order book — sorted price levels, FIFO deques
- [x] Matching — limit + market orders, partial fills, multi-level sweeps, price-time priority
- [x] Tests — comprehensive Swift Testing suite
- [ ] Cancel — remove a resting order by id

- [ ] **Phase 2 — Concurrency** — order book as an actor, stress-tested, throughput measured
- [ ] **Phase 3 — Network layer** — TCP via Network.framework, multiple concurrent clients
- [ ] **Phase 4 — Polish** — live terminal view, profiling, and latency numbers
