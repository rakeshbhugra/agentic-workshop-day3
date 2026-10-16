#!/usr/bin/env bash
# Day 3 pre-flight check for Mac/Linux. Run: bash check.sh
ok=1
show() { # status name message
  case $1 in
    OK) printf '\033[32mOK    %-8s %s\033[0m\n' "$2" "$3";;
    SKIP) printf '\033[33mSKIP  %-8s optional. To add it: %s\033[0m\n' "$2" "$3";;
    *) printf '\033[31mFIX   %-8s %s\033[0m\n' "$2" "$3"; ok=0;;
  esac
}
ver() { command -v "$1" >/dev/null && "$1" --version 2>&1 | head -1; }
v=$(ver codex);  [ -n "$v" ] && show OK codex "$v"  || show FIX codex 'npm install -g @openai/codex   then: codex login'
v=$(ver git);    [ -n "$v" ] && show OK git "$v"    || show FIX git 'xcode-select --install   (or brew install git)'
sdk=$(command -v dotnet >/dev/null && dotnet --list-sdks 2>/dev/null | grep -E '^([89]|[0-9][0-9])\.' | tail -1 | cut -d' ' -f1)
[ -n "$sdk" ] && show OK dotnet "SDK $sdk" || show FIX dotnet 'brew install dotnet@8   (or https://dot.net)'
v=$(ver node);   [ -n "$v" ] && show OK node "$v"   || show FIX node 'brew install node'
v=$(ver docker); [ -n "$v" ] && show OK docker "$v" || show SKIP docker 'install Docker Desktop'
here=$(cd "$(dirname "$0")" && pwd)
case $here in */workshop/day3) show OK folder "$here";; *) show FIX folder "kit is in $here. Put it in ~/workshop/day3 instead.";; esac
echo
[ $ok = 1 ] && echo 'ALL OK. You are ready for Day 3.' || echo 'Fix the red lines, then run bash check.sh again.'
