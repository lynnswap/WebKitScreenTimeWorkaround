#!/bin/bash
set -euo pipefail

task_repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$task_repo_root"

task_output="${1:-$task_repo_root/.build/documentation}"
task_base_path="${2:-WebKitScreenTimeWorkaround}"
task_derived_data="$(mktemp -d "${TMPDIR:-/tmp}/WebKitScreenTimeWorkaround-docs.XXXXXX")"
trap 'rm -rf "$task_derived_data"' EXIT

xcodebuild docbuild \
    -scheme WebKitScreenTimeWorkaround \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$task_derived_data" \
    CODE_SIGNING_ALLOWED=NO \
    OTHER_DOCC_FLAGS='--warnings-as-errors --analyze --experimental-documentation-coverage --coverage-summary-level detailed'

xcrun docc process-archive transform-for-static-hosting \
    "$task_derived_data/Build/Products/Debug-iphoneos/WebKitScreenTimeWorkaround.doccarchive" \
    --output-path "$task_output" \
    --hosting-base-path "$task_base_path"

cat > "$task_output/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0; url=./documentation/webkitscreentimeworkaround/">
    <title>WebKitScreenTimeWorkaround Documentation</title>
</head>
<body>
    <a href="./documentation/webkitscreentimeworkaround/">WebKitScreenTimeWorkaround documentation</a>
</body>
</html>
HTML
