#!/usr/bin/env bash
# Independently verify the marts dbt built, straight against Athena (no dbt).
# Run after scripts/demo.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/env.sh

REGION="$DBT_ATHENA_REGION"
DB="$DBT_ATHENA_SCHEMA"
WG="$DBT_ATHENA_WORKGROUP"

athena_run() {
  local qid state
  qid="$(aws athena start-query-execution --region "$REGION" --work-group "$WG" \
    --query-execution-context "Database=$DB" --query-string "$1" \
    --query 'QueryExecutionId' --output text)"
  while true; do
    state="$(aws athena get-query-execution --region "$REGION" --query-execution-id "$qid" \
      --query 'QueryExecution.Status.State' --output text)"
    case "$state" in
      SUCCEEDED) echo "$qid"; return 0 ;;
      FAILED|CANCELLED) echo "query $state" >&2; return 1 ;;
      *) sleep 2 ;;
    esac
  done
}
scalar() {
  local qid; qid="$(athena_run "$1")"
  aws athena get-query-results --region "$REGION" --query-execution-id "$qid" \
    --query 'ResultSet.Rows[1].Data[0].VarCharValue' --output text
}

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; FAILED=1; }
FAILED=0

echo "1. Gold marts exist and are Parquet"
for t in category_revenue daily_revenue; do
  FMT="$(aws glue get-table --region "$REGION" --database-name "$DB" --name "$t" \
    --query 'Table.StorageDescriptor.OutputFormat' --output text 2>/dev/null || echo NONE)"
  [[ "$FMT" == *parquet* ]] && pass "$t is Parquet" || fail "$t format=$FMT"
done

echo "2. Silver -> gold revenue reconciles"
G="$(scalar "SELECT cast(round(sum(revenue),2) as varchar) FROM category_revenue")"
S="$(scalar "SELECT cast(round(sum(line_total),2) as varchar) FROM stg_orders")"
[[ "$G" == "$S" ]] && pass "gold=$G silver=$S" || fail "gold=$G silver=$S"

echo "3. Staging dropped no valid rows (seed has no bad rows -> 5000 survive)"
N="$(scalar "SELECT cast(count(*) as varchar) FROM stg_orders")"
[[ "$N" == "5000" ]] && pass "stg_orders rows=$N" || fail "stg_orders rows=$N"

echo "4. daily_revenue is one row per day within the 90-day seed window"
D="$(scalar "SELECT cast(count(*) as varchar) FROM daily_revenue")"
[[ "$D" -ge 1 && "$D" -le 90 ]] && pass "distinct days=$D" || fail "distinct days=$D"

echo
[[ "$FAILED" == "0" ]] && echo "All checks passed." || { echo "Some checks failed."; exit 1; }
