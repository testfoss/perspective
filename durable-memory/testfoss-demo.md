# Testfoss demo

## Provenance

The fork branch is `testfoss-demo`, based on upstream Perspective `024bba8e6f4e93f8a2b7680a54d2e01400db18df` (v5.8.0).
The isolated source-build lab recorded build provenance and Playwright acceptance on 2026-11-08; no upstream source patch was used.

The lab used Node.js 22.20.0, pnpm 12.18.0, CMake 3.29.6, Rust nightly-2026-10-01, Emscripten 5.0.3, Binaryen 132, and Chrome 157 through Playwright.
The fork pins `lmwebtest` to `2920befd355eacc654697820d690db074e94dce3` and invokes its Playwright host with LMScript 0.2.463.

## Lab-proven commands

```sh
pnpm install
PACKAGE=metadata,server,client,viewer,viewer-datagrid,viewer-charts PSP_FAST=1 PSP_NUM_CPUS=2 pnpm run build
PACKAGE=client PSP_FAST=1 PSP_NUM_CPUS=2 pnpm test -- --chrome rust/perspective-js/test/js/clear.spec.ts
PACKAGE=viewer-datagrid PSP_FAST=1 PSP_NUM_CPUS=2 pnpm test -- --chrome packages/viewer-datagrid/test/js/config_defaults.spec.ts
PACKAGE=viewer-charts PSP_FAST=1 PSP_NUM_CPUS=2 pnpm test -- --chrome packages/viewer-charts/test/ts/config-defaults.spec.ts
cd examples/esbuild-example && pnpm start -p 8101 -c-1
```

The focused suites passed 8 client, 2 datagrid, and 1 chart test.
The browser loaded local `perspective-server.wasm`, `perspective-viewer.wasm`, and `superstore.lz4.arrow` with HTTP 200.
Acceptance measured 9,994 table rows, four rows after the Category pivot including the grand total, and 2,121 rows for `Category == Furniture`.
The only lab console error was a nonfunctional missing-favicon 404; the additive static server answers that request with 204 instead.

## Fork workflow

`testfoss/run.sh` reproduces the focused build and tests, serves the official built example without changing it, and runs `testfoss/scenario.lms` through `lmwebtest playwright`.
The workflow installs only the required six-package build and pinned browser host, uses read-only repository permission and SHA-pinned actions, and has no deployment or secrets.
Exact local commands and browser-only reuse are documented in `testfoss/README.md`.

## Limitations

The lab and fork scenario validate the debug/source-built browser path, not a release artifact or every Perspective plugin.
The lab was not a native GPU benchmark.
The expensive build was not repeated while authoring this additive content.
The new scenario passed all 10 lmwebtest checks against the existing lab-built upstream server with `/usr/bin/google-chrome`; the screenshot visually confirmed the Furniture result.
Fresh-install schema discovery and syntax checks also passed, while the full source build and Actions run remain CI validation.
GitHub-hosted CMake and other unversioned system packages may differ from the lab's exact host tools.
