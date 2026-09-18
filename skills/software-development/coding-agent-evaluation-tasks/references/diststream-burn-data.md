# Diststream Burn Data (3-Turn Arc So Far)

Diststream is a stream processing engine built from scratch. Greenfield project with skeleton repo.

T1: Core Abstractions. Record, Source, Operator, Pipeline, Sink, Stream, Exceptions. 29-61 tests. A: ~96K, B: ~164K.
T2: Operators + Windowing + State. 10 operators, 3 window types, 2 state backends, fuzzer, 75-check gate. A: 291K, B: 245K. Mega-burns. 370 tests each.
T3: Flow + Semantics + Checkpointing + CLI. Backpressure, dead letter queues, retry, at-least-once/exactly-once, checkpointing, YAML CLI. A: 663K, B: 630K. Both massive. 598-615 tests.

## Pattern

Greenfield builds with many independent modules + property-based fuzzer + mutation proofs + regression + gate consistently burn 200-600K per turn. Each module has its own test file. The fuzzer generates random compositions and verifies invariants. This is the most reliable token-maxxing pattern discovered.
