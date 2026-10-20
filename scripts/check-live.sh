#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
binary_dir=$(swift build -c release --show-bin-path)
binary="$binary_dir/GPTVoice"
[[ -x "$binary" ]] || { echo "Build the app first with ./scripts/build.sh" >&2; exit 1; }
sample_dir=$(mktemp -d -t codex-dictation-check)
trap 'rm -rf "$sample_dir"' EXIT
say -o "$sample_dir/sample.aiff" 'This is a dictation test for Codex.'
afconvert -f WAVE -d LEI16@24000 -c 1 "$sample_dir/sample.aiff" "$sample_dir/sample.wav"
"$binary" --transcribe "$sample_dir/sample.wav"
