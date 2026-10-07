#!/bin/bash
# Prepend a "moved to sscng" banner to the Docker Hub README of every old
# (monolithic) dataeditors/stataNN repository, leaving the existing text
# unchanged. Repos that already carry the banner are skipped.
#
# Requires: curl, jq, docker-pushrm (https://github.com/christian-korneck/docker-pushrm),
# and `docker login` with write access to the source org.

SRC=${SRC:-dataeditors}
DST=${DST:-sscng}
MAXVER=${MAXVER:-17}
WEBSITE=https://ssc-ng.net
# GitHub URL of this repository, derived from the origin remote
GITHUB=$(git remote get-url origin | sed -E 's#^git@github.com:#https://github.com/#; s#\.git$##')
DRYRUN=

while getopts nh flag
do
    case "${flag}" in
        n) DRYRUN=1;;
        *) cat << EOF

$0 [-n]

Prepends a banner pointing to $DST to the README of each $SRC/stataNN
repository with NN <= $MAXVER.
  -n   dry run: write the new READMEs to a temp dir, do not push
  -h   this help
Environment: SRC, DST, MAXVER override the defaults.
EOF
           exit 2;;
    esac
done

for cmd in curl jq git; do
    command -v $cmd >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }
done
[[ -z $DRYRUN ]] && { docker pushrm --help >/dev/null 2>&1 || { echo "Missing: docker pushrm" >&2; exit 1; }; }
[[ -z $GITHUB ]] && { echo "Could not derive GitHub URL from origin remote" >&2; exit 1; }

WORKDIR=$(mktemp -d)
echo "Working directory: $WORKDIR"

# all repositories of the source org
repos=()
url="https://hub.docker.com/v2/repositories/${SRC}/?page_size=100"
while [[ -n $url && $url != null ]]; do
    page=$(curl -fsS "$url") || { echo "Failed: $url" >&2; exit 1; }
    repos+=( $(echo "$page" | jq -r '.results[].name') )
    url=$(echo "$page" | jq -r '.next')
done

ok=0; skip=0; fail=0
for repo in "${repos[@]}"; do
    # old repos are named stataNN, with NN <= MAXVER
    [[ $repo =~ ^stata([0-9]+)$ ]] || continue
    (( BASH_REMATCH[1] <= MAXVER )) || continue

    readme="$WORKDIR/${repo}.md"
    current="$WORKDIR/${repo}.orig.md"
    # keep the README byte-for-byte (jq -j: no added newline; no command substitution, which strips trailing newlines)
    curl -fsS "https://hub.docker.com/v2/repositories/${SRC}/${repo}/" | jq -j '.full_description // ""' > "$current" \
        || { echo "FAILED to fetch README: ${SRC}/${repo}" >&2; fail=$((fail+1)); continue; }

    if grep -qF "hub.docker.com/r/${DST}/${repo}" "$current"; then
        echo "SKIP (banner present): ${SRC}/${repo}"
        skip=$((skip+1))
        continue
    fi

    cat > "$readme" << EOF
> **This image has moved to [\`${DST}/${repo}\`](https://hub.docker.com/r/${DST}/${repo}).**
> New information can be found at [${GITHUB}](${GITHUB}) and at [${WEBSITE}](${WEBSITE}).

EOF
    cat "$current" >> "$readme"

    echo "${SRC}/${repo}: $readme"
    [[ -n $DRYRUN ]] && continue
    if docker pushrm --file "$readme" "${SRC}/${repo}"; then
        ok=$((ok+1))
    else
        echo "FAILED to push README: ${SRC}/${repo}" >&2
        fail=$((fail+1))
    fi
done

echo "Done: $ok updated, $skip skipped, $fail failed."
[[ $fail -eq 0 ]]
