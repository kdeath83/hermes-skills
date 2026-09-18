Task: SQLAlchemy - asyncpg InternalClientError poisons the connection pool
Repo: sqlalchemy/sqlalchemy (Python, 217 files)
Max time: 150 minutes per model

Q1: Task Goal

The goal of this task is for the models to trace, debug and resolve random pool timeout errors within the SQLAlchemy solution.
The primary set of sucess criteria are:
1\  accurately understand the codebase and context of observed errors (binary yes/no)
2\ accurately simulate and trace observed pool timeout errors using asyncpg (binary yes/no)
3\ fix error handling within InterfaceError without impactin existing error handling within the function (binary yes/no)
4\ resulting fix results in >99% sucessful throughput of cases and <0.1% asyncpg.InternalClientError observed

Q2: Why would frontier models struggle with this?

Models should struglle with resolving this bug as it cuts across crosses four architectural layers... 1\ the asyncpg dialect error classification 2\ the engine exception handler 3\ the pool connection return path and 4\ the pre-ping validation. The models need to trace the multi-file path to understand that the  5% silent misclassification at the dialect layer eventually causes the global pool exhaustion.
When PostgreSQL terminates a session mid-transaction, the asyncpg driver can raise InternalClientError instead of the expected InterfaceError. The dialect's is_disconnect() in lib/sqlalchemy/dialects/postgresql/asyncpg.py only checks connection.is_closed() and InterfaceError text. InternalClientError inherits from a different exception hierarchy and is never matched. The engine's handle_dbapi_exception() in engine/base.py calls dialect.is_disconnect() and only invalidates the connection if it returns True. When it returns False, the connection is re-checked in via pool's finalize_fairy() in pool/base.py. This only terminates connections flagged via InvalidationError or is_disconnect.... Pre-ping (pool/impl.py QueuePool._do_pre_ping()) runs a test query but since the TCP socket is still open, it passes the ping, and the corrupted asyncpg protocol state comes on the next real query.

Q3: What does this codebase do?

SQLAlchemy is the Python SQL toolkit and Object Relational Mapper that gives application developers the full power and flexibility of SQL. SQLAlchemy provides a full suite of well known enterprise-level persistence patterns, designed for efficient and high-performing database access, adapted into a simple and Pythonic domain language.
Major SQLAlchemy features include:
An industrial strength ORM, built from the core on the identity map, unit of work, and data mapper patterns. These patterns allow transparent persistence of objects using a declarative configuration system. Domain models can be constructed and manipulated naturally, and changes are synchronized with the current transaction automatically.
A relationally-oriented query system, exposing the full range of SQL's capabilities explicitly, including joins, subqueries, correlation, and most everything else, in terms of the object model. Writing queries with the ORM uses the same techniques of relational composition you use when writing SQL. While you can drop into literal SQL at any time, it's virtually never needed.

Q4:  What issues or gaps does the codebase have, and how would adeveloper get started on solving them?

The gap is that the asyncpg dialect's is_disconnect() method (asyncpg.py:is_disconnect) has an incomplete exception type check. It catches InterfaceError which maps to asyncpg's PostgresError-based exceptions but not InternalClientError which is raised when asyncpg's internal protocol state machine detects corruption. This is obviouslt different from a database-level error. This error only shows up when PostgreSQL terminates a session during a transaction and the asyncpg client reads the termination on the next operation... the internal buffer state returns a InternalClientError instead of the standard InterfaceError.
A L4/5 SWE should start by writing a failing test that:
1\ connects via asyncpg through SQLAlchemy
2\ simulates a server-side session kill via pg_terminate_backend or setting idle_in_transaction_session_timeout low
3\ executes a query against the terminated connection
4\ confirms the connection is invalidated and not returned to the pool.... then trace through asyncpg.py:is_disconnect() to confirm InternalClientError is not caught, and add isinstance(e, self.dbapi.InternalClientError) alongside the existing InterfaceError check.
5\ verify the fix propagates correctly through engine/base.py Connection._handle_dbapi_exception() and pool/base.py_finalize_fairy()


--- Model A

Model Name:
Start:
End:
Total:

Prompt A1 - Opening (auto-injected, identical for both)

I'm seeing random pool timeout errors in production with SQLAlchemy 2.0.x using
asyncpg. Under load the connection pool fills with dead records and new requests
get QueuePool limit timeout errors. I've inspected manually and the database
itself is healthy, and restarting the app fixes it temporarily. I've traced it
to PostgreSQL terminating idle transaction sessions after the configured
timeout. SQLAlchemy catches most of these as InterfaceError and correctly
invalidates the connection. But about 5% of cases surface as
asyncpg.InternalClientError instead, and those are NOT being handled as
disconnects. The corrupted connection goes back into the pool, passes the
pre-ping check as the TCP socket is still open, then fails on the next actual
query. I've been looking at the asyncpg dialect's is_disconnect() method and the
pool base code. There looks like there is a pattern but it's spread across
multiple files and hard for me to track. Can you trace the error recovery path
end to end and add InternalClientError to the disconnect detection? I need a fix
that catches this edge case without breaking the existing error handling for
InterfaceError.

Prompt A2 - Reproduce first

Before changing anything, reproduce it. What is the smallest test that makes
asyncpg surface InternalClientError against a terminated session here? If you
cannot reproduce it deterministically, say so and explain exactly what you would
need to observe it.

Prompt A3 - Trace the path

Now trace what happens to the connection after the exception is raised. Follow
it from the driver through the engine to the pool. Where does it get checked
back in rather than invalidated, and why does pre-ping fail to catch a
connection in this state?

Prompt A4 - Implement

Implement the minimal fix now that you have traced the path.

Prompt A5 - Code review

Please review the code generated for logic, performance and security bugs. produce a report in MD format with findings rated by critical, high and low. make sure each finding explicitly states the filename, filepath and line number and the suggested fix.

Prompt A6 - Verify

Write the test that proves it:
- connect via asyncpg through SQLAlchemy
- kill the backend session
- run a query against the dead connection
- assert the connection is invalidated, not returned to the pool
Also confirm existing InterfaceError handling and healthy connections are
unaffected. Run the dialect and pool suites.

Prompt A7

Please compile the code and produce a compilation report as an MD

--- Model B

Model Name:
Start:
End:
Total:

Prompt B1 - Opening (auto-injected, identical for both)

I'm seeing random pool timeout errors in production with SQLAlchemy 2.0.x using
asyncpg. Under load the connection pool fills with dead records and new requests
get QueuePool limit timeout errors. I've inspected manually and the database
itself is healthy, and restarting the app fixes it temporarily. I've traced it
to PostgreSQL terminating idle transaction sessions after the configured
timeout. SQLAlchemy catches most of these as InterfaceError and correctly
invalidates the connection. But about 5% of cases surface as
asyncpg.InternalClientError instead, and those are NOT being handled as
disconnects. The corrupted connection goes back into the pool, passes the
pre-ping check as the TCP socket is still open, then fails on the next actual
query. I've been looking at the asyncpg dialect's is_disconnect() method and the
pool base code. There looks like there is a pattern but it's spread across
multiple files and hard for me to track. Can you trace the error recovery path
end to end and add InternalClientError to the disconnect detection? I need a fix
that catches this edge case without breaking the existing error handling for
InterfaceError.

Prompt B2 - Point at the exact place

Start in lib/sqlalchemy/dialects/postgresql/asyncpg.py at the is_disconnect
method. It checks connection.is_closed() and InterfaceError text.
InternalClientError comes from a different exception parent in asyncpg, so it
never matches the existing check. Then look at engine/base.py
Connection._handle_dbapi_exception, which uses the is_disconnect result to
decide whether to invalidate.

Prompt B3 - Confirm the mechanism, reproduce

Before implementing, confirm you can reproduce it. Kill a session server-side
(pg_terminate_backend, or a low idle_in_transaction_session_timeout), run a
query, and capture the exact exception. Then walk me through why the connection
gets checked back in instead of invalidated, and why pre-ping passes a
connection in this state.

Prompt B4 - Implement the specific fix

In asyncpg.py, extend is_disconnect to also match
isinstance(e, self.dbapi.InternalClientError), alongside the current
InterfaceError branch. Keep it to the dialect - do not change engine/base.py or
pool/*.py unless you can justify why.

Prompt B5 - Code review

Please review the code generated for logic, performance and security bugs. produce a report in MD format with findings rated by critical, high and low. make sure each finding explicitly states the filename, filepath and line number and the suggested fix.

Prompt B6 - Verify

Write the test that proves it:
- connect via asyncpg through SQLAlchemy
- kill the backend session
- run a query against the dead connection
- assert the connection is invalidated, not returned to the pool
Also confirm existing InterfaceError handling and healthy connections are
unaffected. Run the dialect and pool suites.

Prompt B7

Please compile the code and produce a compilation report as an MD
