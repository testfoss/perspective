#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
UPSTREAM_REV="024bba8e6f4e93f8a2b7680a54d2e01400db18df"
MODE="${1:-}"
PORT="${TESTFOSS_PORT:-8101}"
ARTIFACTS="$HERE/.artifacts"
SERVER_PID=""

cleanup() {
    if [[ -n "$SERVER_PID" ]]; then
        kill "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

verify_upstream() {
    git -C "$ROOT" merge-base --is-ancestor "$UPSTREAM_REV" HEAD || {
        echo "The pinned upstream revision is not an ancestor of HEAD." >&2
        exit 1
    }
    git -C "$ROOT" diff --quiet "$UPSTREAM_REV" -- \
        . ':(exclude)README.md' ':(exclude)AGENTS.md' ':(exclude)durable-memory' \
        ':(exclude)testfoss' ':(exclude).github/workflows/testfoss.yml' || {
        echo "A non-allowlisted path differs from the pinned upstream revision." >&2
        exit 1
    }
}

wait_ready() {
    local url="$1"
    for _ in {1..120}; do
        if curl --fail --silent --output /dev/null "$url"; then
            return 0
        fi
        sleep 1
    done
    echo "Server did not become ready: $url" >&2
    return 1
}

chrome_path() {
    (cd "$HERE" && node --input-type=module -e "import { chromium } from 'playwright'; console.log(chromium.executablePath())")
}

for tool in git node npm curl lmscript; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "Required tool is not on PATH: $tool" >&2
        exit 1
    }
done
verify_upstream
bash -n "$HERE/run.sh"
node --check "$HERE/static-server.mjs"
export PATH="$HERE/node_modules/.bin:$PATH"
npm ci --prefix "$HERE"
lmscript -e 'let host_schema = load_schema(cli="lmwebtest playwright");'
lmscript --check "$HERE/scenario.lms"

if [[ "$MODE" == "--check" ]]; then
    exit 0
fi
if [[ "$MODE" != "" && "$MODE" != "--browser-only" ]]; then
    echo "Usage: $0 [--check|--browser-only]" >&2
    exit 2
fi

CHROME_PATH="${CHROME:-$(chrome_path)}"
if [[ ! -x "$CHROME_PATH" ]]; then
    [[ -z "${CHROME:-}" ]] || {
        echo "CHROME is not executable: $CHROME_PATH" >&2
        exit 1
    }
    npm exec --prefix "$HERE" -- playwright install chromium
fi
export CHROME="$CHROME_PATH"

if [[ "$MODE" != "--browser-only" ]]; then
    for tool in pnpm cmake cargo rustc python3; do
        command -v "$tool" >/dev/null 2>&1 || {
            echo "Required build tool is not on PATH: $tool" >&2
            exit 1
        }
    done
    pnpm --dir "$ROOT" install --frozen-lockfile
    PACKAGE=metadata,server,client,viewer,viewer-datagrid,viewer-charts \
        PSP_FAST=1 PSP_NUM_CPUS=2 CARGO_BUILD_JOBS=2 pnpm --dir "$ROOT" run build
    PACKAGE=client PSP_FAST=1 PSP_NUM_CPUS=2 \
        pnpm --dir "$ROOT" test -- --chrome rust/perspective-js/test/js/clear.spec.ts
    PACKAGE=viewer-datagrid PSP_FAST=1 PSP_NUM_CPUS=2 \
        pnpm --dir "$ROOT" test -- --chrome packages/viewer-datagrid/test/js/config_defaults.spec.ts
    PACKAGE=viewer-charts PSP_FAST=1 PSP_NUM_CPUS=2 \
        pnpm --dir "$ROOT" test -- --chrome packages/viewer-charts/test/ts/config-defaults.spec.ts
    pnpm --dir "$ROOT/examples/esbuild-example" build
fi

DIST="$ROOT/examples/esbuild-example/dist"
for artifact in index.html perspective-server.wasm perspective-viewer.wasm superstore.lz4.arrow; do
    [[ -f "$DIST/$artifact" ]] || {
        echo "Missing $DIST/$artifact; run without --browser-only first." >&2
        exit 1
    }
done
mkdir -p "$ARTIFACTS"
node "$HERE/static-server.mjs" "$DIST" "$PORT" >"$ARTIFACTS/server.log" 2>&1 &
SERVER_PID=$!
wait_ready "http://127.0.0.1:$PORT/"
TESTFOSS_URL="http://127.0.0.1:$PORT" TESTFOSS_ARTIFACTS="$ARTIFACTS" \
    lmscript "$HERE/scenario.lms"
verify_upstream
