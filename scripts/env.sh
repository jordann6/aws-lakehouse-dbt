#!/usr/bin/env bash
# Export the dbt-athena connection from terraform outputs. Sourced by demo.sh
# and validate.sh so the profile stays environment-driven and uncommitted.
set -euo pipefail
_TF="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform" && pwd)"
_tf() { terraform -chdir="$_TF" output -raw "$1"; }

# Declare then export separately so a failing terraform command surfaces its
# exit status instead of being masked by the export builtin.
DBT_ATHENA_REGION="$(_tf aws_region)"
DBT_ATHENA_SCHEMA="$(_tf glue_database)"
DBT_ATHENA_WORKGROUP="$(_tf athena_workgroup)"
DBT_ATHENA_S3_STAGING="$(_tf s3_staging_dir)"
DBT_ATHENA_S3_DATA="s3://$(_tf bucket)/dbt-data/"
DBT_PROFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../dbt" && pwd)"
export DBT_ATHENA_REGION DBT_ATHENA_SCHEMA DBT_ATHENA_WORKGROUP
export DBT_ATHENA_S3_STAGING DBT_ATHENA_S3_DATA DBT_PROFILES_DIR
