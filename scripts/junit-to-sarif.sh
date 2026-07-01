#!/bin/sh
# bun-toolchain bun-test convert (SPEC-047 REQ-001): bun writes failures to STDERR,
# so the JUnit reporter emits results to a FILE (stdout_artifact); normalized here to
# SARIF test findings via POSIX awk. One finding per <testcase> carrying <failure>/<error>.
echo "bun-toolchain junit-to-sarif: normalizing bun test failures to test findings" >&2
awk '
  function jesc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\t/,"\\t",s); return s }
  function xunesc(s){ gsub(/&apos;/,"\047",s); gsub(/&quot;/,"\"",s); gsub(/&lt;/,"<",s); gsub(/&gt;/,">",s); gsub(/&amp;/,"\\&",s); return s }
  function attr(s,name,   re,m){ re="[ ]" name "=\"[^\"]*\""; if(match(s,re)){ m=substr(s,RSTART,RLENGTH); sub(/^[^\"]*\"/,"",m); sub(/\"$/,"",m); return m } return "" }
  BEGIN{ printf "{\"version\":\"2.1.0\",\"runs\":[{\"results\":["; sep=""; pend=0 }
  { line=$0; gsub(/<testcase /,"\n<testcase ",line); gsub(/<\/testcase>/,"\n</testcase>\n",line); gsub(/<failure/,"\n<failure",line); gsub(/<error/,"\n<error",line); n=split(line,arr,"\n")
    for(i=1;i<=n;i++){ t=arr[i]
      if(t ~ /^<testcase /){ nm=xunesc(attr(t,"name")); fl=xunesc(attr(t,"file")); lnn=attr(t,"line")+0; failed=0; pend=1; if(t ~ /\/>[ ]*$/) pend=0 }
      else if(pend && (t ~ /^<failure/ || t ~ /^<error/)){ failed=1 }
      else if(t ~ /^<\/testcase>/){ if(pend && failed){ printf "%s{\"ruleId\":\"bun-test\",\"level\":\"error\",\"message\":{\"text\":\"Test failed: %s\"},\"locations\":[{\"physicalLocation\":{\"artifactLocation\":{\"uri\":\"%s\"},\"region\":{\"startLine\":%d}}}]}", sep, jesc(nm), jesc(fl), (lnn>0?lnn:1); sep="," } pend=0 }
    }
  }
  END{ printf "]}]}\n" }'
