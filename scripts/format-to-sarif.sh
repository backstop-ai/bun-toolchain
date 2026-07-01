#!/bin/sh
# bun-toolchain prettier format convert (SPEC-047 REQ-001 / DD-3).
# Re-expresses prettier's format result OUTSIDE the core binary as a
# LINT-CATEGORY SARIF findings engine: reads `prettier --list-different` output on
# stdin and emits one located SARIF finding per UNFORMATTED file on stdout. Format
# is modeled as lint (DD-3) — these findings ride the EXISTING lint dimension; no
# new "format" gate dimension exists. A converter banner on stderr exercises the
# clean-stdout (SandboxedRunStdout) capture; it never reaches the SARIF bytes.
#
# `prettier --list-different` prints one bare <path> per unformatted file to
# STDOUT (its human `--check` output goes to stderr, which the findings dispatch
# never captures — that stream mismatch silently greened a dirty tree). Each
# non-empty line IS an unformatted file path. Region is file-level (startLine 1) —
# a formatting issue spans the file. Findings are level "warning": format is
# style-class, surfaced as a non-blocking advisory (DD-3), not a gate-reddening
# defect. Implemented in POSIX awk (no gawk-only features) so it runs under the
# macOS system awk inside the sandbox.
echo "bun-toolchain format-to-sarif: normalizing unformatted files to lint findings" >&2

awk '
  BEGIN { printf "{\"version\":\"2.1.0\",\"runs\":[{\"results\":["; sep="" }
  function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, "\\t", s); return s }
  {
    file = $0
    gsub(/^[ \t]+/, "", file); gsub(/[ \t]+$/, "", file)
    # Each non-empty stdout line is an unformatted file path. Skip blanks and any
    # stray prettier diagnostic that leaked to stdout (a real path has no leading
    # "[" bracket that prettier uses for its [warn]/[error] log prefixes).
    if (file == "" || substr(file, 1, 1) == "[") next
    printf "%s{\"ruleId\":\"prettier\",\"level\":\"warning\",\"message\":{\"text\":\"File is not formatted (prettier --list-different)\"},\"locations\":[{\"physicalLocation\":{\"artifactLocation\":{\"uri\":\"%s\"},\"region\":{\"startLine\":1}}}]}", sep, esc(file)
    sep=","
  }
  END { printf "]}]}\n" }
'
