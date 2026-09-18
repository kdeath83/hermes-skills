Task: SQLAlchemy - asyncpg InternalClientError poisons the connection pool
Repo: sqlalchemy/sqlalchemy (Python, 217 files)
Max time: 150 minutes per model
Note: the opening prompt is the approved pre-work prompt. It is auto-injected
and is identical for both models. Only the follow-ups diverge.

--- TRACK A - Independent Problem Solving (Model A)

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

Prompt A5 - Code review and behavioural findings

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

Prompt B5 - Code review and behavioural findings

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
