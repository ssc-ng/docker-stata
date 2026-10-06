#!/bin/bash
# Retag ALL images (every repository, every tag) from the Docker Hub org
# "dataeditors" to the equivalent name in the org "sscng".
# Copies server-side with `docker buildx imagetools create`, so no pull/push
# of layers is needed and multi-arch manifests are preserved.
#
# Tags containing "-broken" are skipped.
#
# Requires: docker (buildx), curl, jq; `docker login` with push rights on sscng.

SRC=${SRC:-dataeditors}
DST=${DST:-sscng}
DRYRUN=

while getopts nh flag
do
    case "${flag}" in
        n) DRYRUN=1;;
        *) cat << EOF2

$0 [-n]

Retags every image under Docker Hub org $SRC as $DST/<same repo>:<same tag>.
  -n   dry run: only print what would be done
  -h   this help
Environment: SRC, DST override the organizations.
EOF2
           exit 2;;
    esac
done

for cmd in docker curl jq; do
    command -v $cmd >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }
done

# fetch all pages of a Docker Hub API list endpoint, printing the given jq field
hub_list() {
    local url=$1 field=$2 page
    while [[ -n $url && $url != null ]]; do
        page=$(curl -fsS "$url") || { echo "Failed: $url" >&2; return 1; }
        echo "$page" | jq -r ".results[].${field}"
        url=$(echo "$page" | jq -r '.next')
    done
}

repos=$(hub_list "https://hub.docker.com/v2/repositories/${SRC}/?page_size=100" name) || exit 1
[[ -z $repos ]] && { echo "No repositories found under $SRC" >&2; exit 1; }

ok=0; fail=0; skip=0
for repo in $repos; do
    tags=$(hub_list "https://hub.docker.com/v2/repositories/${SRC}/${repo}/tags?page_size=100" name) || { fail=$((fail+1)); continue; }
    for tag in $tags; do
        if [[ $tag == *-broken* ]]; then
            echo "SKIP (broken): ${SRC}/${repo}:${tag}"
            skip=$((skip+1))
            continue
        fi
        echo "${SRC}/${repo}:${tag} -> ${DST}/${repo}:${tag}"
        [[ -n $DRYRUN ]] && continue
        if docker buildx imagetools create -t "${DST}/${repo}:${tag}" "${SRC}/${repo}:${tag}"; then
            ok=$((ok+1))
        else
            echo "FAILED: ${SRC}/${repo}:${tag}" >&2
            fail=$((fail+1))
        fi
    done
done

echo "Done: $ok retagged, $skip skipped (-broken), $fail failed."
[[ $fail -eq 0 ]]
