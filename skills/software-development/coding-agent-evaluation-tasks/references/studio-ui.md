# Mercor Studio Interface

From user screenshots, the Studio UI has three main panels:

## Tasks Dashboard
- Table view with columns: Task Name, Task Status, Created By, Updated By, Needs Attention From, Criteria, Latest Score, Latest Model
- Paginated (showing 1-9 per page, "showing 1-9 of 100 rows")
- 88 dashboards available
- Filters: Unowned, Filter, Columns, Group
- Task names, status icons visible

## Source / Metadata Panel
- Source field (default: "Auto")
- Organization field
- Created date/time (e.g., "06/18/2026, 12:15:00 PM EDT")

## AutoQC Panel
- "AUTOMATED QC" header with AutoQC toggle
- Automated check across 7 quality dimensions
- Can press "Run" to self-check before submitting
- **Advisory only** — does not change task status, does not replace human reviewer
- Available while drafting

## Key Workflow
1. Create task in Studio (via "Creating Tasks" workflow)
2. Fill in repo, prompt, rationales
3. Run AutoQC to self-check
4. Clear submission checklist
5. Submit for human review
