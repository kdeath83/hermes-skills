Mercor Task Spec - etcd (Prefilled)

Repository and Tags

Repo Name: etcd-io/etcd
GitHub URL: https://github.com/etcd-io/etcd
Primary Language: Go
Task Type: Debugging
Domain(s): Backend, DevOps/SRE
Interaction Mode: Interactive

Opening Prompt (Interactive Mode)

etcd cluster in staging is losing leases under leader elections. When the
leader changes, some leases expire even though their TTL has not elapsed and
the client that holds them is still alive.

I traced the lease renewal path in lease/lessor.go and the expiry loop in
lease/lease.go. It looks like when a new leader takes over, it rebuilds the
lease expiry heap from the persisted entries. But the persisted timestamp and
the wall clock on the new leader might not match the previous leaders clock,
causing leases to look expired when they are not.

Investigate the lease promotion path during leader election. The issue is that
etcd persists remaining TTL not absolute expiry time, and the new leaders
expiry loop recalculates based on when it applied the raft log entry, not when
the lease was originally granted. Fix it so leases survive leader transitions
correctly.

Rationale 1: Why would frontier models struggle with this?

The bug crosses the raft state machine boundary into the lease expiry subsystem.
When a leader election happens, the new leader must reconstruct the in-memory
lease expiry state from the raft log. The lease proto in lease/lease.go stores
a remaining TTL, and the new leaders expiry loop in lease/lessor.go recalculates
the absolute expiry from the raft apply time. If the apply is delayed by even a
few seconds, leases that were close to their TTL get expired prematurely.

The model has to understand the raft apply loop in raft/raft.go and
etcdserver/raft.go, how the lessor in lease/lessor.go picks up newly applied
entries, and how the expiry goroutine in lease/lease.go decides a lease is
stale. The interaction between raft log index and wall clock based lease expiry
is subtle and easy to get wrong.

Rationale 2: What does this codebase do?

etcd is a Go distributed key-value store that uses the Raft consensus protocol
for replication. About 691 source files. The server is in etcdserver/ which
wraps the raft library in raft/. The storage engine is in mvcc/ and backend/.
Lease management is in lease/ with the lessor controlling expiry and the lease
struct maintaining TTL state. The API layer is in api/ and client code is in
clientv3/.

Rationale 3: What issues or gaps does the codebase have, and how would a
developer get started on solving them?

The lease expiry heap is rebuilt on leader promotion using persisted remaining
TTL. But the absolute expiry time is calculated from the moment the raft entry
is applied, not from the original lease grant time. If a lease had 5 seconds
left when the old leader went down and the new leader takes 3 seconds to detect
the failure, elect, and apply the lease entry, the new leader gives the lease
only 2 more seconds instead of the full 5.

Write a test that starts a three node cluster, creates a lease with a 10 second
TTL, kills the leader, waits for election, and checks that the lease survives
for the remaining TTL. Then trace the apply path in etcdserver/raft.go through
to lessor.go Promote and the expiry goroutine in lease.go.

Pre-Submit Checklist

Repo is etcd-io/etcd, public, not restricted
691 Go source files, CNCF graduated project
Real distributed systems issue - lease expiry on leader election
Done means leases survive leader transitions within their original TTL
Spans lease/, etcdserver/, raft/ packages
L5 level - distributed consensus and clock boundary reasoning
Debugging type matches the investigation
Prompt describes a concrete production scenario
Rationales reference specific packages and the timing mechanism
AutoQC before submit
