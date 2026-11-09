# Perspective Testfoss demo

This additive demo builds the official `examples/esbuild-example` from the pinned source and tests its real Superstore table through [lmwebtest](https://github.com/lmctl-ai/lmwebtest).
No upstream example, package, lockfile, or existing workflow is patched.

## Run

Prerequisites are Bash, Git, Node.js 22.20.0, pnpm 12.18.0, CMake, Rust with the targets from `rust-toolchain.toml`, Python 3, and `lmscript` 0.2.463 (`npm install -g @lmctl-ai/lmctl@0.2.463`).
The runner installs the pinned lmwebtest package and Chromium if needed.

```sh
./testfoss/run.sh
```

The full run executes `pnpm install --frozen-lockfile`, builds only `metadata,server,client,viewer,viewer-datagrid,viewer-charts` with `PSP_FAST=1 PSP_NUM_CPUS=2`, runs the three focused upstream suites (11 tests), builds the official example, and runs `scenario.lms` via `cli="lmwebtest playwright"`.
It checks 9,994 source rows, a four-row Category pivot including the grand total, a 2,121-row Furniture filter, both local Wasm resources, and browser errors.

For an existing build, use `./testfoss/run.sh --browser-only`.
For syntax checks without a build, use `./testfoss/run.sh --check`.
Set `TESTFOSS_PORT` to change the default loopback port 8101.
Set `CHROME` to use an existing Chrome/Chromium executable instead of the pinned Playwright browser.
Generated logs and screenshots stay in the ignored `testfoss/.artifacts/` directory.

CI is defined in `.github/workflows/testfoss.yml`; it has read-only repository permission, no secrets or deployment, pinned actions, and a 90-minute timeout.
The upstream project and this additive demo remain Apache-2.0 licensed.
