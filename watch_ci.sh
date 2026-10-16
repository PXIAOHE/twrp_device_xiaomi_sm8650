#!/bin/sh
# Usage: sh watch_run.sh <run_id> <label>
RUN=$1
LABEL=$2
API=https://api.github.com/repos/PXIAOHE/twrp_device_xiaomi_sm8650
LOG=/workspace/sm8750_yarp/run${RUN}_monitor.log
echo "[$(date '+%F %T')] monitor start for run $RUN ($LABEL)" >> "$LOG"
i=0
while [ $i -lt 80 ]; do
  i=$((i+1))
  RESULT=$(curl -s -m 30 -H "User-Agent: eta" "$API/actions/runs/$RUN" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    s=d.get("status") or "unknown"
    c=d.get("conclusion") or ""
    print(s, c)
except Exception:
    print("parse_error", "x")
')
  echo "[$(date '+%F %T')] poll#$i -> $RESULT" >> "$LOG"
  case "$RESULT" in
    completed*)
      {
        echo "===== RUN COMPLETED ====="
        echo "result: $RESULT"
        curl -s -m 30 -H "User-Agent: eta" "$API/actions/runs/$RUN/jobs" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    for j in d.get("jobs",[]):
        print("job:", j["name"], "->", j.get("conclusion"))
        for s in j.get("steps",[]):
            print("   %-46s %s" % (s["name"], s.get("conclusion")))
except Exception as e:
    print("jobs detail error:", e)
'
        echo "===== ci-logs branch check ====="
        curl -s -m 30 -H "User-Agent: eta" "$API/contents/.ci-logs?ref=ci-logs" | python3 -c '
import json,sys
try:
    d=json.load(sys.stdin)
    if isinstance(d, list):
        for f in d:
            print("ci-logs file:", f["name"], f.get("size"))
    else:
        print(d.get("message"))
except Exception as e:
    print("ci-logs check error:", e)
'
        echo "===== releases ====="
        curl -s -m 30 -H "User-Agent: eta" "$API/releases?per_page=2" | python3 -c '
import json,sys
try:
    rs=json.load(sys.stdin)
    for r in rs[:2]:
        print("release:", r.get("tag_name"), "|", r.get("name"))
        for a in r.get("assets",[]):
            print("   asset:", a["name"], a["size"], a.get("digest"))
except Exception as e:
    print("release detail error:", e)
'
      } >> "$LOG" 2>&1
      echo "MONITOR_DONE"
      exit 0
      ;;
    unknown*|parse_error*)
      sleep 300
      ;;
    *)
      sleep 180
      ;;
  esac
done
echo "monitor timeout after 80 polls" >> "$LOG"
echo "MONITOR_TIMEOUT"
