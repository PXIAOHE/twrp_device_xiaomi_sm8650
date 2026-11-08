#!/bin/bash
# 心跳推送：每 N 秒把构建日志尾部推到 hb 分支。
# 上一版死在 git push 无超时上：第一次推成功后，第二次 push 卡住，循环再也不动。
# 现在每次 git 操作都套 timeout，卡住就丢弃这一拍，下一拍继续。
# 用法：heartbeat.sh <日志文件> [间隔秒]
LOG="${1:?logfile required}"
INTERVAL="${2:-120}"
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

    NOW=$(date +%s)
    ELAPSED=$(( NOW - ${JOB_START:-$NOW} ))
    {
        echo "== $(date -u +%FT%TZ) =="
        echo "job_elapsed_s: $ELAPSED"
        echo "log: $LOG"
        echo "size_bytes: $(stat -c%s "$LOG" 2>/dev/null || echo 0)"
        echo "lines: $(wc -l < "$LOG" 2>/dev/null || echo 0)"
        echo "--- mem ---";  free -m   2>/dev/null | head -3
        echo "--- disk ---"; df -h / "$GITHUB_WORKSPACE" 2>/dev/null | tail -3
        echo "--- tail 24000 bytes ---"
        tail -c 24000 "$LOG" 2>/dev/null
    } > "$HB_DIR/live.log" 2>/dev/null

    [ -s "$HB_DIR/live.log" ] || continue

    timeout 20 git add -f live.log >/dev/null 2>&1
    timeout 20 git commit -q -m "heartbeat $(date -u +%H:%MZ)" >/dev/null 2>&1
    # 关键：push 必须有超时，否则整个循环卡死
    timeout 60 git push -q -f origin HEAD:hb >/dev/null 2>&1
done