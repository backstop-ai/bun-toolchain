#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

junit=$(sh "$root/scripts/junit-to-sarif.sh" < "$root/testdata/captured/bun-test-failure.xml")
printf '%s' "$junit" | jq -e '.version == "2.1.0" and (.runs[0].results | length) == 1' >/dev/null
printf '%s' "$junit" | jq -e '.runs[0].results[0].locations[0].physicalLocation.artifactLocation.uri == "test/example.test.ts"' >/dev/null

coverage=$(sh "$root/scripts/coverage-to-records.sh" < "$root/testdata/captured/bun-coverage.lcov")
printf '%s' "$coverage" | jq -e 'length == 4' >/dev/null
printf '%s' "$coverage" | jq -e 'any(.[]; .path == "src/example.ts" and .metric == "line" and .covered == 3 and .total == 4)' >/dev/null
printf '%s' "$coverage" | jq -e 'any(.[]; .path == "src/example.ts" and .metric == "branch" and .covered == 1 and .total == 2)' >/dev/null
printf '%s' "$coverage" | jq -e 'any(.[]; .path == "src/no-branches.ts" and .metric == "branch" and .total == 0)' >/dev/null

typecheck=$(printf '%s\n' 'src/example.ts(7,12): error TS2322: Type string is not assignable to type number.' | sh "$root/scripts/tsc-to-sarif.sh")
printf '%s' "$typecheck" | jq -e '.runs[0].results[0].ruleId == "TS2322" and .runs[0].results[0].locations[0].physicalLocation.region.startLine == 7' >/dev/null

format=$(printf '%s\n' 'src/example.ts' | sh "$root/scripts/format-to-sarif.sh")
printf '%s' "$format" | jq -e '.runs[0].results[0].ruleId == "prettier"' >/dev/null

oxlint=$(sh "$root/scripts/oxlint-to-sarif.sh" < "$root/testdata/captured/oxlint-checkstyle.xml")
printf '%s' "$oxlint" | jq -e '.runs[0].results[0].ruleId == "eslint(no-debugger)" and .runs[0].results[0].locations[0].physicalLocation.region.startLine == 3' >/dev/null

printf '%s\n' "converter fixtures passed"
