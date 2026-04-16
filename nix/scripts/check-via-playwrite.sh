#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <script-name>" >&2
  exit 1
fi

script_name="$1"
fixture_path="test/$script_name.contains.json"

if [ ! -f "$fixture_path" ]; then
  echo "Fixture not found: $fixture_path" >&2
  exit 1
fi

actual_path="$(mktemp)"
missing_path="$(mktemp)"

cleanup() {
  rm -f "$actual_path" "$missing_path"
}

trap cleanup EXIT

./nix/scripts/run-via-playwrite.sh "$script_name" >"$actual_path"

jq -n \
  --slurpfile actual "$actual_path" \
  --slurpfile fixture "$fixture_path" \
  '
    def as_items:
      if type == "array" then . else [.] end;

    ($actual[0] | as_items) as $actual_items
    | ($fixture[0] | as_items) as $fixture_items
    | [
        $fixture_items[]
        | select(. as $needle | any($actual_items[]; contains($needle)) | not)
      ]
  ' >"$missing_path"

if [ "$(jq 'length' "$missing_path")" -ne 0 ]; then
  echo "Fixture mismatch for $script_name:" >&2
  cat "$missing_path" >&2
  exit 1
fi
