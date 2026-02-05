# Self-Hosting Status

This directory tracks the Coatl bootstrap compiler and seed maintenance flow.

## Current State

- Bootstrap compiler is implemented in `selfhost/bootstrap.coatl`.
- Convergence checks are automated.
- Seed refresh is automated.
- Runtime suites validate generated compiler output.

## Main Commands

Regular seeded compile path:
```bash
./selfhost/build_with_selfhost.sh build ./examples/hello.coatl -o /tmp/hello-self.wat
wasmtime --invoke main /tmp/hello-self.wat
```

Convergence checks:
```bash
./selfhost/check_self_compile.sh
./selfhost/check_self_compile_seed.sh
```

Roundtrip/runtime checks:
```bash
./selfhost/run_roundtrip_suite.sh
./selfhost/run_roundtrip_suite_seed.sh
./selfhost/run_selfhost_runtime_suite.sh
./selfhost/run_no_rust_ci.sh
```

Refresh committed seed:
```bash
./selfhost/update_seed.sh
```

## Notes

- `main()` in bootstrap supports compile mode for deterministic stdin->stdout compilation.
- Output normalization and convergence checks are performed by helper scripts.
- See `selfhost/SELFHOSTING_GUIDE.md` for deeper design notes.
