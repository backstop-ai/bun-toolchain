#!/bin/sh
# bun-toolchain tsc convert (SPEC-047 REQ-001): tsc --noEmit prints plain-text
# "file(line,col): error TSxxxx: msg" (never SARIF). Normalized to SARIF build
# findings via POSIX awk. Clean typecheck -> empty stdin -> empty (valid) SARIF.
echo "bun-toolchain tsc-to-sarif: normalizing tsc diagnostics to build findings" >&2
awk '
  function jesc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\t/,"\\t",s); return s }
  BEGIN{ printf "{\"version\":\"2.1.0\",\"runs\":[{\"results\":["; sep="" }
  {
    if(match($0, /\([0-9]+,[0-9]+\): error TS[0-9]+: /)){
      file=substr($0,1,RSTART-1); rest=substr($0,RSTART)
      match(rest,/[0-9]+,[0-9]+/); lc=substr(rest,RSTART,RLENGTH); split(lc,a,","); ln=a[1]+0; cl=a[2]+0
      match(rest,/TS[0-9]+/); code=substr(rest,RSTART,RLENGTH)
      match(rest,/error TS[0-9]+: /); msg=substr(rest,RSTART+RLENGTH)
      printf "%s{\"ruleId\":\"%s\",\"level\":\"error\",\"message\":{\"text\":\"%s\"},\"locations\":[{\"physicalLocation\":{\"artifactLocation\":{\"uri\":\"%s\"},\"region\":{\"startLine\":%d,\"startColumn\":%d}}}]}", sep, code, jesc(msg), jesc(file), ln, cl; sep=","
    }
  }
  END{ printf "]}]}\n" }'
