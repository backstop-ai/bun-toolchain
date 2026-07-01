#!/bin/sh
# bun-toolchain oxlint convert (SPEC-047 REQ-001): oxlint has no native SARIF; its
# --format=checkstyle XML is normalized here to SARIF lint findings. POSIX awk only
# (the sandboxed convert runner cannot reach /usr/local/bin, so node is unavailable).
echo "bun-toolchain oxlint-to-sarif: normalizing oxlint checkstyle to lint findings" >&2
awk '
  function jesc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/\t/,"\\t",s); return s }
  function xunesc(s){ gsub(/&apos;/,"\047",s); gsub(/&quot;/,"\"",s); gsub(/&lt;/,"<",s); gsub(/&gt;/,">",s); gsub(/&amp;/,"\\&",s); return s }
  function attr(s,name,   re,m){ re="[ ]" name "=\"[^\"]*\""; if(match(s,re)){ m=substr(s,RSTART,RLENGTH); sub(/^[^\"]*\"/,"",m); sub(/\"$/,"",m); return m } return "" }
  BEGIN{ printf "{\"version\":\"2.1.0\",\"runs\":[{\"results\":["; sep="" }
  { line=$0; gsub(/<file /,"\n<file ",line); gsub(/<error /,"\n<error ",line); n=split(line,arr,"\n")
    for(i=1;i<=n;i++){
      if(arr[i] ~ /^<file /){ curfile=xunesc(attr(arr[i],"name")) }
      else if(arr[i] ~ /^<error /){
        ln=attr(arr[i],"line")+0; cl=attr(arr[i],"column")+0
        sev=attr(arr[i],"severity"); lvl=(sev=="error")?"error":"warning"
        msg=xunesc(attr(arr[i],"message")); rule=xunesc(attr(arr[i],"source"))
        printf "%s{\"ruleId\":\"%s\",\"level\":\"%s\",\"message\":{\"text\":\"%s\"},\"locations\":[{\"physicalLocation\":{\"artifactLocation\":{\"uri\":\"%s\"},\"region\":{\"startLine\":%d,\"startColumn\":%d}}}]}", sep, jesc(rule), lvl, jesc(msg), jesc(curfile), ln, cl; sep=","
      }
    }
  }
  END{ printf "]}]}\n" }'
