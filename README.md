# backstop/bun-toolchain

Reusable Bun/TypeScript native-toolchain **mechanism** pack for
[backstop](https://github.com/backstop-ai). It runs the Bun stack's
lint/format/typecheck/test/coverage passes through backstop's engine-dispatch
substrate and normalizes their output to SARIF (findings) or coverage-records —
carrying **no** coding-standards rules (mechanism only, mirroring
`backstop/go-toolchain`).

Hand-authored from the `backstop/go-toolchain` `pack.yml` template (the pack-authoring
CLI reboot is tracked separately as ISSUE-032).

## Engines

| Engine | Command | Gate dimension |
| --- | --- | --- |
| `oxlint` | `oxlint --format=json` | lint |
| `prettier` | `prettier --check` | lint (format-as-lint; **no** new "format" dimension) |
| `typecheck` | `tsc --noEmit` | build |
| `bun-test` | `bun test` | test |
| `bun-coverage` | `bun test --coverage --coverage-reporter=lcov` | coverage |

The coverage engine writes an lcov report and `scripts/coverage-to-records.sh`
normalizes it into per-file **line + branch** coverage records (two records per file,
raw counts). `scripts/format-to-sarif.sh` turns `prettier --check`'s unformatted-file
list into lint-category SARIF findings.

## Classification

Source: `**/*.ts`, `**/*.tsx` — Test: `**/*.test.ts`, `**/*.spec.ts`
(the language-neutral coverage consumer reads these globs instead of a baked literal).

## Install

```sh
backstop pack add backstop/bun-toolchain --from <path-or-git>
```

Then declare it in `backstop.yml`:

```yaml
packs:
    backstop/bun-toolchain: local
```

## Toolchain

`oxlint`, `bun`, `tsc`, `prettier` must be on PATH (Layer-0 runtime tools backstop
does not auto-provision). They are presence-pinned on backstop's trusted-tool
allowlist.
