#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <script-name>" >&2
  exit 1
fi

script_name="$1"
script_path=""

for candidate in "scripts/$script_name" "scripts/$script_name.js"; do
  if [ -f "$candidate" ]; then
    script_path="$candidate"
    break
  fi
done

if [ -z "$script_path" ]; then
  echo "Script not found in scripts/: $script_name" >&2
  exit 1
fi

session_output="$(playwriter session new 2>&1)"
# `session new` prints progress lines before the final "Session N created..." line.
session_id="$(
  printf '%s\n' "$session_output" |
    sed -n 's/^Session \([0-9][0-9]*\) created\..*/\1/p' |
    tail -n1
)"

if [ -z "$session_id" ]; then
  printf '%s\n' "$session_output" >&2
  echo "Could not parse Playwriter session id" >&2
  exit 1
fi

cleanup() {
  playwriter session delete "$session_id" >/dev/null 2>&1 || true
}

output_path="$(mktemp)"

cleanup_all() {
  rm -f "$output_path"
  cleanup
}

trap cleanup_all EXIT

playwriter_code="$(
  cat <<'EOF'
state.page = state.page ?? page ?? context.pages()[0] ?? await context.newPage()

const output = await state.page.evaluate(async () => {
  const logs = []
  const originalConsoleLog = console.log
  console.log = (...args) => {
    const line = args.map((arg) => {
      if (typeof arg === 'string') return arg
      try {
        return JSON.stringify(arg)
      } catch {
        return String(arg)
      }
    }).join(' ')
    logs.push(line)
  }

  try {
    const returnValue = await (async () => {
EOF
cat "$script_path"
cat <<'EOF'
    })()

    if (logs.length > 0) {
      return logs.join('\n')
    }

    if (typeof returnValue === 'undefined') {
      return ''
    }

    if (typeof returnValue === 'string') {
      return returnValue
    }

    return JSON.stringify(returnValue, null, 2)
  } finally {
    console.log = originalConsoleLog
  }
})

require('fs').writeFileSync('__OUTPUT_PATH__', output, 'utf8')
EOF
)"

# Playwriter truncates `-e` text output to 10k chars, so write the full result to a temp file instead.
playwriter_code="$(printf '%s' "$playwriter_code" | sed "s|__OUTPUT_PATH__|$output_path|g")"

playwriter -s "$session_id" -e "$playwriter_code" >/dev/null

jq -e . "$output_path" >/dev/null

cat "$output_path"
