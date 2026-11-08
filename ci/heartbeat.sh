#!/bin/bash
# 心跳推送：定期把构建日志尾部推到 hb 分支，供 runner 被杀后取证。
# 用法：heartbeat.sh <build日志> [间隔秒] [watch日志]
# 每次心跳内容：时间 / job 已跑秒数 / 两份日志的大小与行数 / 内存 / 磁盘 /
#               build 日志尾部 16KB / watch 日志尾部 2KB
BUILD_LOG="${1:?build log required}"
INTERVAL="${2:-120}"
WATCH_LOG="${3:-}"
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
        echo "build_log: $BUILD_LOG"
        echo "build_size_bytes: $(stat -c%s "$BUILD_LOG" 2>/dev/null || echo 0)"
        echo "build_lines: $(wc -l < "$BUILD_LOG" 2>/dev/null || echo 0)"
        if [ -n "$WATCH_LOG" ]; then
            echo "watch_lines: $(wc -l < "$WATCH_LOG" 2>/dev/null || echo 0)"
        fi
        echo "--- mem ---";  free -m 2>/dev/null | head -3
        echo "--- disk ---"; df -h / "$GITHUB_WORKSPACE" 2>/dev/null | tail -3
        echo "--- build tail 16000 bytes ---"
        tail -c 16000 "$BUILD_LOG" 2>/dev/null
        if [ -n "$WATCH_LOG" ]; then
            echo "--- watch tail 2000 bytes ---"
            tail -c 2000 "$WATCH_LOG" 2>/dev/null
        fi
    } > "$HB_DIR/live.log" 2>/dev/null

    [ -s "$HB_DIR/live.log" ] || continue

    timeout 20 git add -f live.log >/dev/null 2>&1
    timeout 20 git commit -q -m "heartbeat $(date -u +%H:%MZ)" >/dev/null 2>&1
    timeout 60 git push -q -f origin HEAD:hb >/dev/null 2>&1
done