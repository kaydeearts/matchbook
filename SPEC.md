# matchbook — Concurrent Matching Engine

**Swift · structured concurrency (actors, `Sendable`) · Network.framework · Instruments**

A local electronic exchange: a server holding an **order book** that matches buy/sell
orders by **price-time priority**, accessed concurrently by many trader clients over TCP.

A modern-stack revival of a Systems Architecture II project (a concurrent exchange
server in C — pthreads, locks, semaphores, sockets). The point of *this* version is the
delta: the concurrency correctness that was held together by hand with mutexes and
semaphores is now enforced by the compiler via actor isolation and `Sendable`, the
transport is Network.framework, and throughput / latency / correctness are **measured**.

---

## Goal & what to build toward

**Project highlights (the capabilities to aim for):**

> **matchbook — Concurrent Matching Engine** — Swift, Network.framework
> - An electronic-exchange matching engine with a price-time-priority order book
>   (limit + market orders, partial fills, cancels), served to concurrent trader clients over TCP.
> - The order book modeled as an **actor** so all mutations are serialized and data-race-free;
>   `Sendable` enforcing the safety **at compile time** — where an earlier C implementation of the
>   same problem used manual locks/semaphores.
> - Correctness verified under concurrent load (no lost orders, no double-fills, conservation of
>   shares & cash), with **[N] orders/sec** throughput and **p50/p99 [X]/[Y] µs** submit→ack latency.

Only keep the points you actually build. Fill in the real `[N]`/`[X]`/`[Y]`.

**Est. effort:** ~26–34 build hours (~6–7 weeks at evening pace). Slightly higher than a minimal
version because a credible matching engine includes cancels and a real concurrency stress test —
both high-value. **First demoable milestone at end of Phase 2.**

---

## Architecture (target)

```
  trader client ─┐
  trader client ─┼── TCP (Network.framework) ──▶  matchbook server
  trader client ─┘                                    │
                                                       ▼
                                           MatchingEngine (actor)
                                        ┌───────────────────────────┐
                                        │  order book               │
                                        │   bids: price → [orders]  │  price-time
                                        │   asks: price → [orders]  │  priority
                                        └───────────────────────────┘
                                                       │
                                             trades ───┴──▶ fills + trade tape → clients
```

- **`MatchingEngine`** (library target) — pure order book + matching. No I/O, fully testable.
- **`matchbook`** (executable target) — Phase 1 a scripted driver; Phase 3 the TCP server.

---

## Phase 1 — Matching engine core (single-threaded, in-process)

*The intellectual core. Get it correct before adding a single thread or socket.*

- [x] **Project setup** — SPM package builds; `swift build` + `swift test` run green. *(scaffolded)*
- [ ] **Domain types** — `Order` (id, side, type, price, quantity, timestamp), `Side`
      (buy/sell), `OrderType` (limit/market), `Trade` (maker/taker ids, price, quantity).
      Round-trip / print to confirm. *(1–2h)*
- [ ] **Order book structure** — bids and asks organized by price level, FIFO within a
      level; add and inspect resting orders. Best bid / best ask accessible cheaply. *(2–3h)*
- [ ] **Limit-order matching** — an incoming order crosses the book at the maker's price,
      generates trades, handles partial fills, rests any remainder. *(2–3h)*
- [ ] **Market orders** — sweep best levels until filled or the book is empty. *(1–2h)*
- [ ] **Cancel** — remove a resting order by id; it no longer participates in matches. *(1h)*
- [ ] **Unit tests** — the worked example below, partial fills, price-time priority, market
      sweeps, cancel, empty-book edge cases, conservation of shares & cash. *(2–3h)*

**Worked example the tests should cover:**
```
Book empty.
A: BUY  100 @ $10 (limit) → no sellers, rests on bid side
B: SELL  50 @ $10 (limit) → crosses A → TRADE 50 @ $10; A has 50 resting
C: SELL 100 @ $11 (limit) → above best bid, rests on ask side
D: BUY   60 @ market      → takes best ask → TRADE 60 @ $11
```

**Done when:** a scripted order sequence produces correct fills and resting state, proven by tests.

---

## Phase 2 — Concurrency (safe & fast under load)

*The differentiator. This is where the C version's manual locking becomes compiler-enforced.*

- [ ] **Actor boundary** — wrap the engine as an `actor` so all book mutations serialize;
      expose an `async` submit/cancel API. *(2h)*
- [ ] **Stress harness** — many concurrent tasks submitting random orders at once. *(1–2h)*
- [ ] **Correctness under concurrency** — assert invariants: no lost orders, no double-fills,
      conservation of total shares & cash across the whole run. *(2–3h)*
- [ ] **Throughput benchmark** — orders/sec with 1 vs N concurrent submitters; record it. *(1–2h)*
- [ ] **Write down what `Sendable` / actor isolation caught at compile time** (for the README). *(~1h)*

**Done when:** correct under the concurrent stress test, with a measured throughput number.
**← First demoable milestone: a benchmarked, provably-correct engine.**

---

## Phase 3 — Network layer (Network.framework)

- [ ] **TCP listener** — `NWListener`; accept multiple concurrent client connections. *(2–3h)*
- [ ] **Wire protocol** — a simple newline-delimited text protocol
      (e.g. `BUY 100 10.00 LIMIT`, `CANCEL <id>`); parse orders; handle partial reads / framing. *(2–3h)*
- [ ] **Connect clients to the engine** — client submits → engine matches → fills/acks sent back. *(2h)*
- [ ] **Trade tape / book broadcast** — push trades and book updates to connected clients. *(1–2h)*
- [ ] **Trader client** — a minimal client binary (or document driving it with `nc`). *(1–2h, optional)*

**Done when:** two or more real clients trade against each other over TCP.

---

## Phase 4 — Polish, profile, publish

- [ ] **Live terminal view** — order-book depth (both sides) + recent trade tape. *(2–3h)*
- [ ] **Instruments Time Profiler** — profile the matching hot path, optimize, re-measure. *(2–3h)*
- [ ] **Latency** — submit→ack percentiles (p50/p99). *(1–2h)*
- [ ] **README + demo** — the *why*, a demo GIF, before/after numbers; clean up commit history. *(2h)*

**Done when:** live view works; throughput + latency documented; README tells the story.

---

## Scope guardrails (protect the ROI — scope creep is the only real risk)

**In scope:** one instrument; limit + market orders; cancel; price-time priority; TCP line protocol.

**Out of scope (note as future work only):** multiple instruments; stop/iceberg/other order
types; order amend/replace; FIX protocol; persistence/durability & crash recovery; authentication;
a GUI; multi-venue / distributed matching.

---

## Stack

Swift 6 (structured concurrency, actors, `Sendable`), Network.framework (`NWListener`/`NWConnection`),
XCTest or Swift Testing, Instruments (Time Profiler).

## Build & run

```sh
swift build          # build
swift test           # run the engine tests
swift run matchbook  # run the driver / server
```
Open in Xcode for Instruments: `xed .` (or File ▸ Open the package folder).
