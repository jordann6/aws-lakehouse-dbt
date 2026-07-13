#!/usr/bin/env bash
# One-time: create a local venv and install the dbt Athena adapter.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet "dbt-athena-community==1.9.*"
echo "dbt-athena installed. Version:"
dbt --version
