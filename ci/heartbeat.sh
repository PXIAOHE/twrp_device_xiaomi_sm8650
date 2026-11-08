#!/bin/bash
# 心跳推送：每 N 秒把构建日志的尾部推到 hb 分支。
# 目的：GitHub runner 被杀时不会上传任何日志，只能靠这个留下"死前在做什么"。
# 用法：heartbeat.sh <日志文件> [间隔秒]
LOG="${1:?logfile required}"
INTERVAL="${2:-180}"
HB_DIR="${GITHUB_WORKSPACE}/.hb"

mkdir -p "$HB_DIR" || exit 0
cd "$HB_DIR" || exit 0
[ -d .git ] || git init -q .
git config user.name "ci-logs"
git config user.email "ci-logs@users.noreply.github.com"
git remote remove origin 2>/dev/null
git remote add origin "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

while true; do
    sleep "$INTERVAL"
    [ -f "$LOG" ] || continue
    {
        echo "== $(date -u +%FT%TZ) =="
        echo "job_elapsed_s: $(( $(date +%s) - ${JOB_START:-$SECONDS} ))"
        echo "log: $LOG"
        echo "size_bytes: $(stat -c%s "$LOG" 2>/dev/null)"
        echo "lines: $(wc -l < "$LOG" 2>/dev/null)"
        echo "--- tail 25000 bytes ---"
        tail -c 25000 "$LOG"
    } > "$HB_DIR/live.log" 2>/dev/null || continue
    git add -f live.log
    git commit -q -m "heartbeat $(date -u +%H:%MZ)" >/dev/null 2>&1 || true
    git push -q -f origin HEAD:hb >/dev/null 2>&1 || true
done