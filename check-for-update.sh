#!/bin/bash

set -eu

GITHUB_REPOSITORY=quickdocs/dist-extractor

if [ -z ${GITHUB_TOKEN+x} ] || [ "$GITHUB_TOKEN" = "" ]; then
  echo "[Error] GITHUB_TOKEN is not set" >&2
  exit 1
fi

quickdocs_version=$(curl -sSL https://storage.googleapis.com/quickdocs-dist/quicklisp/info.json | jq -r '.latest_version')
quicklisp_version=$(curl -sSL http://beta.quicklisp.org/dist/quicklisp.txt | grep '^version: ' | sed -e 's/version: //')

if [ "$quickdocs_version" = "$quicklisp_version" ]; then
  echo "No updates until the version '$quickdocs_version'."
  exit
fi

echo "Found a new dist version '$quicklisp_version'"
latest_github_deployment=$(curl -sSL -H "Authorization: token $GITHUB_TOKEN" \
  -H 'Accept: application/vnd.github.v3+json' \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/deployments?environment=production \
  | jq -cM '.[0]')
if [ "$(echo $latest_github_deployment | jq -Mr '.payload.version')" = "${quicklisp_version}" ]; then
  latest_github_deployment_state=$(curl -sSL -H "Authorization: token $GITHUB_TOKEN" \
    -H 'Accept: application/vnd.github.v3+json' \
    "$(echo $latest_github_deployment | jq -Mr '.statuses_url')" | jq -Mr '.[0].state')
  if [ "$latest_github_deployment_state" = "in_progress" ] || [ "$latest_github_deployment_state" = "null" ]; then
    echo "Deployment is already running."
    exit
  fi
fi

echo "Creating a deployment."
github_deployment=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H 'Accept: application/vnd.github.v3+json' \
  https://api.github.com/repos/${GITHUB_REPOSITORY}/deployments \
  -d "{\"ref\":\"master\",\"required_contexts\":[],\"payload\":{\"version\":\"${quicklisp_version}\"}}")
echo "Response = $github_deployment"

deployment_id=$(echo "$github_deployment" | jq -r '.id')
if [ "$deployment_id" = "null" ]; then
  message=$(echo "$github_deployment" | jq -r '.message')
  echo "[Error] Failed to create a deployment: $message" >&2
  exit 1
fi

echo "Created a deployment '$deployment_id'."
