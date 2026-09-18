#!/usr/bin/env bash
# Project C (Code Preferences) sprint setup - macOS
#
# macOS equivalent of the old Windows setup.ps1, updated for the current
# sprint tooling (init.py + ./claude-dev + Docker).
#
# Usage:
#   ./setup-macos.sh            # checks only, changes nothing
#   ./setup-macos.sh --install  # also create .venv and install submit.py deps
#
# Run this in the directory where init.py lives.

set -uo pipefail

RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; NC=$'\033[0m'
ok()   { printf "  %sOK%s   %s\n"   "$GRN" "$NC" "$1"; }
warn() { printf "  %sWARN%s %s\n"   "$YLW" "$NC" "$1"; }
bad()  { printf "  %sFAIL%s %s\n"   "$RED" "$NC" "$1"; FAILED=1; }

FAILED=0
INSTALL=0
[ "${1:-}" = "--install" ] && INSTALL=1

echo "Project C sprint setup (macOS)"
echo "=============================="

# ---------------------------------------------------------------- 1. env vars
echo
echo "1. Environment hygiene"
# ANTHROPIC_* override the proxy login; init.py refuses to run if either is set.
for v in ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN; do
  if [ -n "${!v:-}" ]; then
    bad "$v is set in this shell - unset it before running init.py"
  else
    ok "$v unset"
  fi
done
if grep -qhE 'ANTHROPIC_(API_KEY|AUTH_TOKEN)' ~/.zshrc ~/.zprofile ~/.bash_profile 2>/dev/null; then
  warn "ANTHROPIC_* found in a shell profile - remove it so new terminals are clean"
else
  ok "no ANTHROPIC_* in shell profiles"
fi

# Claude Code is a Node tool; give it headroom (was 64000 on Windows)
if [ -n "${CLAUDE_CODE_MAX_OUTPUT_TOKENS:-}" ]; then
  ok "CLAUDE_CODE_MAX_OUTPUT_TOKENS=$CLAUDE_CODE_MAX_OUTPUT_TOKENS"
else
  warn "CLAUDE_CODE_MAX_OUTPUT_TOKENS not set - add to ~/.zshrc:"
  echo "         export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000"
fi

# ------------------------------------------------------------ 2. prerequisites
echo
echo "2. Prerequisites"

if command -v python3 >/dev/null 2>&1; then
  PYV=$(python3 -c 'import sys;print("%d.%d"%sys.version_info[:2])')
  PYN=$(python3 -c 'import sys;print(sys.version_info[0]*100+sys.version_info[1])')
  if [ "$PYN" -ge 307 ]; then ok "python3 $PYV"; else bad "python3 $PYV (need 3.7+)"; fi
else
  bad "python3 not found"
fi

command -v git >/dev/null 2>&1 && ok "git $(git --version | awk '{print $3}')" || bad "git not found"

if command -v claude >/dev/null 2>&1; then
  ok "Claude Code $(claude --version 2>/dev/null | awk '{print $1}') (run 'claude update' periodically)"
else
  bad "claude not found - install Claude Code"
fi

if command -v docker >/dev/null 2>&1; then
  ok "docker $(docker --version | awk '{print $3}' | tr -d ,)"
  if docker info >/dev/null 2>&1; then
    ok "docker daemon running"
  else
    bad "docker daemon not running - start Docker Desktop (init.py blocks without it)"
  fi
else
  bad "docker not found - install Docker Desktop"
fi

# ---------------------------------------------------------------- 3. ssh / git
echo
echo "3. GitHub SSH"
if [ -f "$HOME/.ssh/config" ] && grep -q 'github.com' "$HOME/.ssh/config" 2>/dev/null; then
  ok "~/.ssh/config has a github.com entry"
fi
SSHTEST=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -T git@github.com 2>&1 || true)
if printf '%s' "$SSHTEST" | grep -q "successfully authenticated"; then
  ok "github ssh auth working ($(printf '%s' "$SSHTEST" | sed -n 's/^Hi \([^!]*\)!.*/\1/p'))"
else
  warn "github ssh auth not confirmed - see Appendix B (key setup)"
fi

# ------------------------------------------------------- 4. submit.py deps
echo
echo "4. Submission dependencies (supabase, tuspy)"
if [ -x "./.venv/bin/python" ]; then
  if ./.venv/bin/python -c 'import supabase, tusclient' >/dev/null 2>&1; then
    ok ".venv present with supabase + tuspy"
  else
    warn ".venv present but missing supabase/tuspy"
    [ "$INSTALL" = 1 ] && ./.venv/bin/pip install -q requests supabase tuspy 'pyjwt[crypto]' cryptography
  fi
else
  if [ "$INSTALL" = 1 ]; then
    echo "  creating .venv ..."
    python3 -m venv .venv && ./.venv/bin/pip install -q --upgrade pip \
      && ./.venv/bin/pip install -q requests supabase tuspy 'pyjwt[crypto]' cryptography \
      && ok ".venv created with submit.py dependencies"
    echo "  NOTE: run init.py and submit.py with ./.venv/bin/python"
  else
    warn "no .venv - re-run with --install to create it"
  fi
fi

# ------------------------------------------------------------- 5. task folder
echo
echo "5. Task folder"
if [ -f "./init.py" ]; then
  ok "init.py present in this directory"
else
  warn "init.py not in this directory - cd to where you saved it"
fi
for d in logs/model_a logs/model_b; do
  [ -d "./$d" ] && ok "$d exists" || warn "$d not created yet (init.py makes it)"
done

# ------------------------------------------------------------------- summary
echo
echo "=============================="
if [ "$FAILED" = 1 ]; then
  echo "${RED}Blockers found - fix the FAIL items above before starting a task.${NC}"
  exit 1
else
  echo "${GRN}No blockers.${NC} Warnings are advisory."
  echo
  echo "Next: python3 init.py  (or ./.venv/bin/python init.py)"
fi
