Task: SQLAlchemy - asyncpg InternalClientError poisons the connection pool
Repo: sqlalchemy/sqlalchemy (Python, 217 files)
Max time: 150 minutes per model
Note: the opening prompt is the approved pre-work prompt. It is auto-injected
and is identical for both models. Only the follow-ups diverge.

--- TRACK A - Independent Problem Solving (Model A)

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

Prompt A5 - Verify and regression-test

Prove the fix actually holds:
- the connection is invalidated and not returned to the pool
- the fix propagates through both the engine exception handler and the pool
  return path, not just the dialect
- existing InterfaceError handling is unchanged
- healthy connections still behave normally
Run the relevant test suites and report what passes.

Prompt A6 - Code review and behavioural findings

Optional model prompt (surfaces communication quality and overconfidence):

Walk me through what you changed and why. For each part, tell me where it
could go wrong: any case where it would now invalidate a healthy connection,
any cost it adds to the error path, and any way a connection in this state
could still reach a live request.

Then review the generated diff yourself, independently of what the model
claimed. Cover three dimensions and record each finding as a behavioural
issue (issue type + severity).

Logic
- Does the fix classify InternalClientError correctly without over-broadening,
  i.e. catching unrelated exceptions and invalidating healthy connections?
- Is the isinstance check scoped and ordered correctly?
- Are there sibling exception types with the same gap that were missed?
- Is the pre-ping path consistent with the new classification?

Performance
- The check runs on every DBAPI exception, so does it add real cost to the
  error path?
- Any extra round-trips or I/O introduced?
- Does it avoid over-invalidating and thrashing the pool, which would hurt
  throughput more than the bug it fixes?

Security
- A corrupted connection reused from the pool can leak state across requests
  or tenants. Does the fix actually eliminate that?
- Does the fix swallow or mask real errors?
- Is anything sensitive logged, such as connection strings or bound params?
- Could reusing a half-broken connection corrupt data rather than fail cleanly?

Findings

Finding 1
Model: A
Dimension: Logic / Performance / Security
Issue type: <one of the 13>
Evidence: <file and line in the generated diff>
Severity: Blocking / Major / Minor / Observation

Finding 2
Model: A
Dimension:
Issue type:
Evidence:
Severity:

(continue as needed)

Observation Record - Track A

Model Name:
Start:      End:      Total:

A1:
A2 - reproduced? Y/N:
A3:
A4:
A5 - Tests? Pass? Compiles?

Issue types seen (from the 13):
Notes:


--- TRACK B - Directed Execution (Model B)

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

Prompt B5 - Verify

Write the test that proves it:
- connect via asyncpg through SQLAlchemy
- kill the backend session
- run a query against the dead connection
- assert the connection is invalidated, not returned to the pool
Also confirm existing InterfaceError handling and healthy connections are
unaffected. Run the dialect and pool suites.

Prompt B6 - Code review and behavioural findings

Optional model prompt (surfaces communication quality and overconfidence):

Walk me through what you changed and why. For each part, tell me where it
could go wrong: any case where it would now invalidate a healthy connection,
any cost it adds to the error path, and any way a connection in this state
could still reach a live request.

Then review the generated diff yourself, independently of what the model
claimed. Cover three dimensions and record each finding as a behavioural
issue (issue type + severity).

Logic
- Does the fix classify InternalClientError correctly without over-broadening,
  i.e. catching unrelated exceptions and invalidating healthy connections?
- Is the isinstance check scoped and ordered correctly?
- Are there sibling exception types with the same gap that were missed?
- Is the pre-ping path consistent with the new classification?

Performance
- The check runs on every DBAPI exception, so does it add real cost to the
  error path?
- Any extra round-trips or I/O introduced?
- Does it avoid over-invalidating and thrashing the pool, which would hurt
  throughput more than the bug it fixes?

Security
- A corrupted connection reused from the pool can leak state across requests
  or tenants. Does the fix actually eliminate that?
- Does the fix swallow or mask real errors?
- Is anything sensitive logged, such as connection strings or bound params?
- Could reusing a half-broken connection corrupt data rather than fail cleanly?

Findings

Finding 1
Model: B
Dimension: Logic / Performance / Security
Issue type: <one of the 13>
Evidence: <file and line in the generated diff>
Severity: Blocking / Major / Minor / Observation

Finding 2
Model: B
Dimension:
Issue type:
Evidence:
Severity:

(continue as needed)

Observation Record - Track B

Model Name:
Start:      End:      Total:

B1:
B2:
B3 - reproduced? Y/N:
B4:
B5 - Tests? Pass? Compiles?

Issue types seen (from the 13):
Notes:


--- Final Comparison (individual scores first, then head-to-head)

Individual (1-5):            A     B     evidence
Task Success
Instruction Following
Interaction Quality
Code Quality
Thoroughness
Communication Quality

Head-to-head (0-7 A to B):   score   reasoning with specific evidence
Overall Performance
Instruction Following
Time to Resolution
Vibe
