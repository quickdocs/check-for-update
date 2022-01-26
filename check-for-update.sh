#!/bin/bash

set -eu

GITHUB_REPOSITORY=quickdocs/dist-extractor

if [ -z ${GITHUB_TOKEN+x} ] || [ "$GITHUB_TOKEN" = "" ]; then
  echo "[Error] GITHUB_TOKEN is not set" >&2
  exit 1
fi

quickdocs_version=$(curl -sL https://storage.googleapis.com/quickdocs-dist/quicklisp/info.json | jq -r '.latest_version')
quicklisp_version=$(curl -s -L http://beta.quicklisp.org/dist/quicklisp.txt | grep '^version: ' | sed -e 's/version: //')

if [ "$quickdocs_version" = "$quicklisp_version" ]; then
  echo "No updates until the version '$quickdocs_version'."
  exit
fi

echo "Found a new dist version '$quicklisp_version'"
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
