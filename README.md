# matchbook

A concurrent **electronic-exchange matching engine** in Swift: a server holding an
**order book** that matches buy/sell orders by **price-time priority**, accessed
concurrently by many trader clients over TCP.

<!-- TODO: demo GIF of the live terminal order book + trade tape goes here -->
<!-- ![demo](docs/demo.gif) -->

> **Status:** 🚧 in progress — see [`SPEC.md`](SPEC.md) for the phased plan.

---

## Why this exists

<!-- Fill this in as you build — this is the most important section. Keep it about the WHY. -->

- **Why an order book with price-time priority** — <!-- what the matching rule is and why -->
- **Why an actor for the engine** — <!-- serialized, data-race-free mutation; how Sendable
     enforces at compile time what a C version did by hand with locks/semaphores -->
- **Why Network.framework** — <!-- an exchange is networked by nature; TCP + many clients -->
- **What the concurrency stress test proves** — <!-- no lost orders, no double-fills,
     conservation of shares & cash -->

This is a modern-stack revival of a Systems Architecture II project (a concurrent exchange
server written in C with pthreads, locks, and semaphores). See [`SPEC.md`](SPEC.md).

---

## Design

```
  trader client ─┐
  trader client ─┼── TCP (Network.framework) ──▶  matchbook server ──▶ MatchingEngine (actor)
  trader client ─┘                                                        └─ order book (bids/asks)
```

- **`MatchingEngine`** — pure order book + matching logic. No I/O, fully testable.
- **`matchbook`** — the server / driver executable.

## Build & run

```sh
swift build
swift test
swift run matchbook
```

## Protocol

<!-- TODO: document the wire protocol once Phase 3 lands, e.g.:
  BUY 100 10.00 LIMIT
  SELL 50 MARKET
  CANCEL <order-id>
-->

## Benchmarks

<!-- TODO: fill in real numbers from Phase 2 & 4 -->

| Metric | Result |
| --- | --- |
| Throughput (1 submitter) | _[N]_ orders/sec |
| Throughput (N submitters) | _[N]_ orders/sec |
| Submit→ack latency (p50 / p99) | _[X] / [Y]_ µs |

_Core utilization / hot-path findings from Instruments: TODO._

## Roadmap

- [ ] Phase 1 — matching engine core (limit + market + cancel, tested)
- [ ] Phase 2 — concurrency (actor, stress test, throughput)
- [ ] Phase 3 — network layer (Network.framework, multi-client)
- [ ] Phase 4 — live view, profiling, latency, docs

## Out of scope

Multiple instruments, exotic order types, amend/replace, FIX, persistence/durability,
authentication, GUI, distributed matching. (Noted as possible future work.)
