# Testfoss demo guidance

Read `durable-memory/index.md` before changing the additive demo.

## Boundaries

- Upstream Perspective source, examples, lockfiles, and existing workflows must remain byte-for-byte unchanged from `024bba8e6f4e93f8a2b7680a54d2e01400db18df`.
- Fork content is limited to this file, the README appendix, `durable-memory/`, `testfoss/`, and `.github/workflows/testfoss.yml`.
- Do not commit `node_modules`, build products, screenshots, LFS materialization changes, or other generated output.
- Preserve the Apache-2.0 license and upstream notices.

## Commands

- `./testfoss/run.sh --check` checks shell, JavaScript, and LMScript syntax without compiling Perspective.
- `./testfoss/run.sh` performs the six-package source build, 11 focused upstream tests, and the lmwebtest browser scenario.
- `./testfoss/run.sh --browser-only` reuses an existing build.

The browser scenario must continue to invoke `lmwebtest playwright` through `cli="lmwebtest playwright"`.
Keep the Superstore assertions tied to the real table: 9,994 initial rows, four Category pivot rows including the grand total, and 2,121 Furniture rows.
