#!/bin/sh
set -euo pipefail

export AZURE_CORE_NO_COLOR=1
export AZURE_CORE_ONLY_SHOW_ERRORS=1

MANAGEMENT_GROUPS=""
SUBSCRIPTIONS=""

while getopts "hs:m:" opt; do
  case $opt in
    s)
      SUBSCRIPTIONS="${SUBSCRIPTIONS} ${OPTARG}"
      ;;
    m)
      MANAGEMENT_GROUPS="${MANAGEMENT_GROUPS} ${OPTARG}"
      ;;
    h)
      echo "Usage: $0 [-s subscription] [-m management_group]"
      echo "  -s subscription           Limit to this subscription (can be used multiple times)"
      echo "  -m management_group       Limit to this management group (can be used multiple times)"
      echo "  -h                        Show this help"
      exit 0
      ;;
    \?)
      exit 1
      ;;
    :)
      exit 1
      ;;
  esac
done

if ! command -v az >/dev/null; then
  echo "This script requires azure-cli"
  exit 1
fi

if ! command -v jq >/dev/null; then
  echo "This script requires jq"
  exit 1
fi

if ! az extension show --name resource-graph &>/dev/null; then
  echo "This script requires the Azure resource-graph extension"
  echo "You can install it by running:"
  echo "  az extension add --name resource-graph"
  exit 1
fi

if [ -n "${MANAGEMENT_GROUPS}" ] && [ -n "${SUBSCRIPTIONS}" ]; then
  echo "You can only specify one of -s or -m"
  exit 1
fi

management_groups_flag=""
if [ -n "${MANAGEMENT_GROUPS}" ]; then
  management_groups_flag="--management-group ${MANAGEMENT_GROUPS}"
fi

subscriptions_flag=""
if [ -n "${SUBSCRIPTIONS}" ]; then
  subscriptions_flag="--subscriptions ${SUBSCRIPTIONS}"
fi

echo "type,kind,count"

skip_token=""
while true
do
  resources="$(az graph query -q 'Resources | summarize count() by type, kind | sort by type asc, kind asc' --first 1000 --skip-token "$skip_token" ${management_groups_flag} ${subscriptions_flag})"

  echo "$resources" | jq -re '.data | .[] | [.type, .kind, .count_] | @csv'

  skip_token="$(echo "$resources" | jq -re '.skip_token // empty')"
  if [ -z "$skip_token" ]; then
    break
  fi
done
