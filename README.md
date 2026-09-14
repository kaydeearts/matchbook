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

- [ ] Matching engine core — order book, price-time matching, limit + market + cancel
- [ ] Concurrency — order book as an actor, stress-tested, throughput measured
- [ ] Network layer — TCP via Network.framework, multiple concurrent clients
- [ ] Live terminal view, profiling, and latency numbers
