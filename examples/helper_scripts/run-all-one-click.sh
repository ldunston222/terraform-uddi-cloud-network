#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./examples/helper_scripts/run-all-one-click.sh <action> [--no-init] [-- <terraform args>]

Actions:
  init      Run terraform init for all one-click examples
  plan      Run terraform plan for all one-click examples (default)
  apply     Run terraform apply for all one-click examples
  destroy   Run terraform destroy for all one-click examples
  validate  Run terraform validate for all one-click examples

Examples:
  ./examples/helper_scripts/run-all-one-click.sh plan
  ./examples/helper_scripts/run-all-one-click.sh apply -- -auto-approve
  ./examples/helper_scripts/run-all-one-click.sh destroy -- -auto-approve
  ./examples/helper_scripts/run-all-one-click.sh plan --no-init
EOF
}

action="${1:-plan}"
if [[ "${1:-}" != "" ]]; then
  shift
fi

run_init=true
if [[ "${1:-}" == "--no-init" ]]; then
  run_init=false
  shift
fi

if [[ "${1:-}" == "--" ]]; then
  shift
fi

tf_args=("$@")

case "$action" in
  init|plan|apply|destroy|validate)
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    echo "Unsupported action: $action" >&2
    usage
    exit 1
    ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

examples=(
  "examples/AWS/one-click"
  "examples/Azure/one-click"
  "examples/GCP/one-click"
)

run_tf() {
  local example_dir="$1"
  local subcommand="$2"
  local cmd=(terraform -chdir="$repo_root/$example_dir" "$subcommand")

  if (( ${#tf_args[@]} > 0 )); then
    cmd+=("${tf_args[@]}")
  fi

  echo "==> [$example_dir] terraform $subcommand ${tf_args[*]:-}"
  "${cmd[@]}"
}

for example_dir in "${examples[@]}"; do
  if [[ "$action" == "init" ]]; then
    run_tf "$example_dir" "init"
    continue
  fi

  if [[ "$run_init" == "true" ]]; then
    run_tf "$example_dir" "init"
  fi

  run_tf "$example_dir" "$action"
done

echo "Completed '$action' for all one-click examples."
