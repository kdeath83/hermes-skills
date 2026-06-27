Mercor Task Spec - SQLAlchemy (Prefilled)

Repository and Tags

Repo Name: sqlalchemy/sqlalchemy
GitHub URL: https://github.com/sqlalchemy/sqlalchemy
Primary Language: Python
Task Type: Debugging
Domain(s): Backend
Interaction Mode: Interactive

Opening Prompt (Interactive Mode)

Random pool timeouts in prod with SQLAlchemy 2.0.x + asyncpg. Moderate load and
the connection pool fills with dead records. New requests hit QueuePool limit
timeout. Database is fine - I can connect manually. Restart the app fixes it
temporarily.

PostgreSQL is killing idle-in-transaction sessions after timeout. SA catches
most of these as InterfaceError and invalidates the connection. But maybe 5%
come through as asyncpg.InternalClientError and those slip through. Corrupted
connection goes back in the pool, passes pre-ping because the TCP socket is
still open, then fails on the next real query.

Ive been reading the asyncpg dialect is_disconnect method and the pool base
code. The pattern is there once you spot it but you have to connect dots
across like six files. Trace the error recovery path and add
InternalClientError to disconnect detection. Need a fix that catches this
without breaking existing InterfaceError handling.

Rationale 1: Why would frontier models struggle with this?

The bug crosses four layers. The asyncpg dialect classifies errors, the engine
catches DBAPI exceptions, the pool decides whether to return or kill a
connection, and pre-ping validates connections on checkout. When PG kills a
session mid-transaction, asyncpg can throw InternalClientError instead of
InterfaceError. The dialect is_disconnect in
lib/sqlalchemy/dialects/postgresql/asyncpg.py only checks connection.is_closed
and InterfaceError text. InternalClientError uses a different exception parent,
never matches.

The engines handle_dbapi_exception in engine/base.py calls dialect.is_disconnect
and only invalidates if it returns True. False means the connection goes back
to the pool through finalize_fairy in pool/base.py. Pre-ping in
pool/impl.py QueuePool._do_pre_ping runs a test query but the TCP socket is
still fine. The asyncpg protocol state is what's broken. So the ping passes
and the connection kills the next real query instead.

A 5% silent exception misclassification at the dialect layer cascades into the
pool drying up. The model has to trace through six files across three packages
to see how a small miss in one function poisons the whole pool.

Rationale 2: What does this codebase do?

SQLAlchemy is the Python ORM. 217 source files in lib/. Three layers: the SQL
expression language in sql/ (about 32 files for compiler, selectable, DML,
types), the ORM in orm/ (38 files for session, mapper, relationships), and the
engine in engine/ (20 files for Connection, Result, transactions). Async
support lives in ext/asyncio with AsyncEngine and AsyncSession built on
greenlet spawning. Database dialects are in dialects/. The postgresql dir has
20 files. asyncpg.py is where the asyncpg adapter lives along with its
is_disconnect implementation.

Rationale 3: What issues or gaps does the codebase have, and how would a
developer get started on solving them?

is_disconnect in asyncpg.py catches InterfaceError but not InternalClientError.
These two exceptions come from different parts of asyncpg. InterfaceError wraps
PostgresError - database level failures like connection termination.
InternalClientError means the asyncpg client's protocol state machine detected
corruption internally. It happens in a narrow window when PG kills a session
during a transaction and the client reads the termination signal on the next
operation but the internal buffer state is mid-protocol.

Write a test that connects via asyncpg through SA, kills the backend session
with pg_terminate_backend, runs a query against the dead connection, and
asserts the connection gets invalidated rather than returned to the pool.
Then check is_disconnect in asyncpg.py to confirm InternalClientError is not
in the exception check. Add isinstance(e, self.dbapi.InternalClientError)
next to the existing InterfaceError branch. Then confirm the fix propagates
through handle_dbapi_exception in engine/base.py and finalize_fairy in
pool/base.py.

Pre-Submit Checklist

Repo is sqlalchemy/sqlalchemy, public, not restricted
217 Python source files, used in basically every Python backend
Real production issue - pool corruption under asyncpg load
Done means InternalClientError triggers connection invalidation
6 files across dialect, engine, pool, and async extension
L5 level - needs understanding Python exception hierarchies and connection pooling
Debugging type matches root cause investigation
Prompt reads like someone describing a production outage
Rationales name specific files, exception classes, and the cascade path
AutoQC before submit
