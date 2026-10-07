#!/bin/bash
# Generate and push the Docker Hub README (overview page) for every sscng
# repository of a given Stata version (or all versions), using the same
# template logic as push.sh / set-latest.sh.
#
# Requires: docker, curl, jq, docker-pushrm (https://github.com/christian-korneck/docker-pushrm),
#           and a Docker Hub login with write access to the target org.

DST=${DST:-sscng}
SHORTDESC="Docker image for Stata, to be used in automation and reproducibility."
VERSION=
DRYRUN=

usage() {
cat << EOT

$0 [-v version] [-n] [-h]

Pushes the README for all repositories $DST/stata<version>[-variant].
  -v   Stata version (17, 18, 18_5, 19_5, ...). Default: all stata* repos in $DST
  -n   dry run: generate READMEs and print what would be pushed
  -h   this help
Template: README-containers.template.md for version >= 18, README-containers.early.md otherwise,
plus README-containers.<version>.md if present. Environment: DST overrides the organization.
EOT
exit 2
}

while getopts v:nh flag
do
    case "${flag}" in
        v) VERSION=${OPTARG};;
        n) DRYRUN=1;;
        *) usage;;
    esac
done

for cmd in curl jq; do
    command -v $cmd >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }
done
[[ -z $DRYRUN ]] && ! docker pushrm --help >/dev/null 2>&1 && { echo "Missing: docker-pushrm" >&2; exit 1; }

cd "$(dirname "$0")" || exit 1
tmpdir=$(mktemp -d); trap 'rm -rf "$tmpdir"' EXIT

# list all repositories (all pages) in the target org
repos=
url="https://hub.docker.com/v2/repositories/${DST}/?page_size=100"
while [[ -n $url && $url != null ]]; do
    page=$(curl -fsS "$url") || { echo "Failed: $url" >&2; exit 1; }
    repos+=$(echo "$page" | jq -r '.results[].name')$'\n'
    url=$(echo "$page" | jq -r '.next')
done

ok=0; fail=0
for repo in $repos; do
    # stata<full_version>[-suffix]; full_version is e.g. 17, 18_5
    [[ $repo =~ ^stata([0-9]+(_[0-9]+)?)(-.*)?$ ]] || continue
    full=${BASH_REMATCH[1]}
    [[ -n $VERSION && $full != "$VERSION" ]] && continue
    base=${full%%_*}

    template=README-containers.template.md
    [[ $base -lt 18 ]] && template=README-containers.early.md
    [[ -f $template ]] || { echo "Missing template $template" >&2; fail=$((fail+1)); continue; }

    out="$tmpdir/README-$repo.md"
    sed -e "s/{{ base_version }}/$base/g" -e "s/{{ full_version }}/$full/g" "$template" > "$out"
    if [[ -f README-containers.$full.md ]]; then
        echo "" >> "$out"
        cat "README-containers.$full.md" >> "$out"
    fi

    echo "README ($template) -> ${DST}/${repo}"
    [[ -n $DRYRUN ]] && continue
    if docker pushrm "${DST}/${repo}" --file "$out" --short "$SHORTDESC"; then
        ok=$((ok+1))
    else
        echo "FAILED: ${DST}/${repo}" >&2; fail=$((fail+1))
    fi
done

echo "Done: $ok pushed, $fail failed."
[[ $fail -eq 0 ]]
