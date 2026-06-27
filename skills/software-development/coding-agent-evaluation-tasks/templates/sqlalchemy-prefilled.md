Mercor Task Spec - SQLAlchemy (Prefilled)

Repository and Tags

Repo Name: sqlalchemy/sqlalchemy
GitHub URL: https://github.com/sqlalchemy/sqlalchemy
Primary Language: Python
Task Type: Debugging
Domain(s): Backend
Interaction Mode: Interactive

Opening Prompt (Interactive Mode)

We're seeing random pool timeout errors in production with SQLAlchemy 2.0.x
using asyncpg. Under moderate load, the connection pool fills with dead records
and new requests get QueuePool limit timeout errors. The database itself is
healthy - we can connect manually. Restarting the app fixes it temporarily.

We traced it to PostgreSQL terminating idle-in-transaction sessions after the
configured timeout. SQLAlchemy catches most of these as InterfaceError and
correctly invalidates the connection. But about 5% of cases surface as
asyncpg.InternalClientError instead, and those are NOT being handled as
disconnects. The corrupted connection goes back into the pool, passes the
pre-ping check (TCP socket is still open), then fails on the next actual query.

I've been staring at the asyncpg dialect's is_disconnect() method and the pool
base code. The pattern is clear once you know what to look for, but it's spread
across multiple files. Can you trace the error recovery path end to end and add
InternalClientError to the disconnect detection? We need a fix that catches
this edge case without breaking the existing error handling for InterfaceError.

Rationale 1: Why would frontier models struggle with this?

The bug crosses four architectural layers: the asyncpg dialect error
classification, the engine exception handler, the pool connection return path,
and the pre-ping validation. When PostgreSQL terminates a session
mid-transaction, the asyncpg driver can raise InternalClientError instead of
the expected InterfaceError. The dialect's is_disconnect() in
lib/sqlalchemy/dialects/postgresql/asyncpg.py only checks
connection.is_closed() and InterfaceError text. InternalClientError inherits
from a different exception hierarchy and is never matched. The engine's
handle_dbapi_exception() in engine/base.py calls dialect.is_disconnect() and
only invalidates the connection if it returns True. When it returns False, the
connection is re-checked in via pool's finalize_fairy() in pool/base.py - which
only terminates connections flagged via InvalidationError or is_disconnect.
Then pre-ping (pool/impl.py QueuePool._do_pre_ping()) runs a test query but
since the TCP socket is still open, it passes the ping, and the corrupted
asyncpg protocol state only manifests on the next real query. The model needs
to trace this six-file path to understand that a 5% silent misclassification
at the dialect layer cascades into global pool exhaustion.

Rationale 2: What does this codebase do?

SQLAlchemy is the standard Python ORM and SQL toolkit (217 source files in
lib/). The core is organized into three layers: the SQL expression language
(lib/sqlalchemy/sql/ - 32 files covering the compiler, selectable constructs,
DML, type system), the ORM layer (lib/sqlalchemy/orm/ - 38 files covering the
session, mapper, relationships, loading strategies), and the Engine layer
(lib/sqlalchemy/engine/ - 20 files for Connection, Result, transactions).
The async extension lives in lib/sqlalchemy/ext/asyncio/ providing AsyncEngine
(1487 lines) and AsyncSession (2006 lines) via greenlet spawning. Database
dialects are in lib/sqlalchemy/dialects/ - postgresql/ contains 20 files
including asyncpg.py which implements the asyncpg-specific DBAPI adapter.

Rationale 3: What issues or gaps does the codebase have, and how would a
developer get started on solving them?

The gap is that the asyncpg dialect's is_disconnect() method
(asyncpg.py:is_disconnect) has an incomplete exception type check. It catches
InterfaceError (which maps to asyncpg's PostgresError-based exceptions) but
not InternalClientError, which is raised when asyncpg's internal protocol
state machine detects corruption - distinct from a database-level error. This
exception arises in a narrow window: when PostgreSQL terminates a session
during a transaction (via idle_in_transaction_session_timeout or similar),
and the asyncpg client reads the termination on the next operation, the
internal buffer state can produce InternalClientError instead of the standard
InterfaceError.

A developer would start by writing a failing test that: (1) connects via
asyncpg through SQLAlchemy, (2) simulates a server-side session kill (via
pg_terminate_backend or setting idle_in_transaction_session_timeout low),
(3) executes a query against the terminated connection, (4) asserts the
connection is invalidated and not returned to the pool. Then trace through
asyncpg.py:is_disconnect() to confirm InternalClientError is not caught,
and add isinstance(e, self.dbapi.InternalClientError) alongside the existing
InterfaceError check. Then verify the fix propagates correctly through
engine/base.py Connection._handle_dbapi_exception() and pool/base.py
_finalize_fairy().

Pre-Submit Checklist

Public GH repo, not restricted - sqlalchemy/sqlalchemy, 65k+ stars
200+ code files, enterprise-grade - 217 source files, used by every major Python
backend globally
Realistic production scenario - pool corruption under load is a known operational
pain point
Concrete, testable done - InternalClientError triggers connection invalidation,
pool stays healthy under session-kill conditions
Multi-file change (5-15+ files) - 6 files across dialect, engine, pool, ext/asyncio
L5+ SWE difficulty - requires understanding Python exception hierarchies, DBAPI
protocol, async connection pooling, and error classification dispatch
Task Type matches actual work - Debugging (trace why 5% of disconnect errors evade
detection and cascade into pool exhaustion)
Prompt matches Interaction Mode - short, describes real symptom and likely area,
asks for investigation
Rationales specific, own words - all three name concrete files, exception classes,
and the cascade mechanism
AutoQC passes - run before submit
