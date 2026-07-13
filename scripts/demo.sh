#!/usr/bin/env bash
# Run the analytics-engineering pipeline the way CI or an analyst would:
#   dbt seed  -> load raw_orders into the catalog (bronze)
#   dbt run   -> build stg_orders view (silver) and the Parquet marts (gold)
#   dbt test  -> run every generic + singular data test
#
# This is the whole GitOps loop: the models and tests are code, and one command
# reconciles the warehouse to them.
set -euo pipefail
cd "$(dirname "$0")/.."

# shellcheck disable=SC1091
source .venv/bin/activate
# shellcheck disable=SC1091
source scripts/env.sh

cd dbt

echo "==> dbt debug (connection check)"
dbt debug

echo "==> dbt seed (bronze: load raw_orders)"
dbt seed --full-refresh

echo "==> dbt run (silver view + gold Parquet marts)"
dbt run

echo "==> dbt test (data quality gates)"
dbt test

echo
echo "Pipeline built. Run scripts/validate.sh to independently verify the marts."
