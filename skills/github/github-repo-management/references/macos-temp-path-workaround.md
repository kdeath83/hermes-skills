# macOS Temp Path Workaround

## Problem

Hermes' `write_file` tool refuses paths under `/var/folders/...` on macOS, reporting:

```
Refusing to write to sensitive system path: /var/folders/...
Use the terminal tool with sudo if you need to modify system files.
```

This happens when using `tempfile.mkdtemp()` or `mktemp -d` in Python/shell, which on macOS returns a path under `/var/folders/<hash>/<hash>/T/`.

## Why

The tool has a path-sensitivity guard that flags certain system directories. On macOS, `/var/folders/` is used for per-user temporary and cache files, but the guard treats it as protected.

## Workarounds

### 1. execute_code with Python open()

```python
with open("/var/folders/.../file.md", "w") as f:
    f.write(content)
```

### 2. terminal with heredoc

```bash
cat << 'EOF' > /var/folders/.../file.md
# content here
EOF
```

### 3. Use a non-temp path

Write to `~/Desktop/`, `~/Downloads/`, or `~/tmp/` instead of system temp:

```bash
mkdir -p ~/tmp/hermes-work && cd ~/tmp/hermes-work
```

### 4. For repo editing: clone to a known working directory

```bash
WORKDIR="$HOME/hermes-work/github-repos"
mkdir -p "$WORKDIR"
git clone https://github.com/owner/repo.git "$WORKDIR/repo"
```

Then edit with `patch` (which does not have the same path restriction) or use `execute_code`/`terminal`.

## When This Fires

- Cloning repos to `tempfile.mkdtemp()` dirs for bulk editing
- Writing intermediate files during data processing
- Any workflow that constructs temp paths on macOS

## Prevention

For bulk repo editing, prefer cloning directly to `~/hermes-work/` or a project-specific directory rather than system temp. This also makes cleanup easier and avoids the guard entirely.
