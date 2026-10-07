#!/bin/bash
# Archive (make read-only) all Docker Hub repositories of one Stata version,
# e.g. stata17, stata17-mp, stata17-se-i, ...
#
# NOTE: the archive endpoint below is written from memory and could not be
# verified; check it against https://docs.docker.com/reference/api/hub/ and
# override with ARCHIVE_ENDPOINT if it differs. Use -n first.
#
# Requires: curl, jq; DOCKERHUB_USERNAME and DOCKERHUB_TOKEN (a personal access
# token of a user with admin rights in the org) in the environment.

ORG=${ORG:-sscng}
VERSION=
DRYRUN=
UNARCHIVE=

usage() {
cat << EOT

$0 -v version [-o org] [-n] [-u]

Archives all repositories $ORG/stata<version>[-variant] on Docker Hub.
  -v   Stata version, required (17, 18, 18_5, ...); 18 does not match 18_5
  -o   Docker Hub organization (default: $ORG)
  -n   dry run: only list the repositories
  -u   unarchive instead of archive
  -h   this help
Environment: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN; ARCHIVE_ENDPOINT (path template,
default /v2/repositories/{org}/{repo}/archive; "unarchive" replaces the last word with -u).
EOT
exit 2
}

while getopts v:o:nuh flag
do
    case "${flag}" in
        v) VERSION=${OPTARG};;
        o) ORG=${OPTARG};;
        n) DRYRUN=1;;
        u) UNARCHIVE=1;;
        *) usage;;
    esac
done
[[ -z $VERSION ]] && usage

for cmd in curl jq; do
    command -v $cmd >/dev/null || { echo "Missing: $cmd" >&2; exit 1; }
done

ACTION=archive; [[ -n $UNARCHIVE ]] && ACTION=unarchive
ENDPOINT=${ARCHIVE_ENDPOINT:-/v2/repositories/{org}/{repo}/archive}
ENDPOINT=${ENDPOINT%archive}$ACTION

# list repositories (public listing; add auth for private repos)
repos=
url="https://hub.docker.com/v2/repositories/${ORG}/?page_size=100"
while [[ -n $url && $url != null ]]; do
    page=$(curl -fsS "$url") || { echo "Failed: $url" >&2; exit 1; }
    repos+=$(echo "$page" | jq -r '.results[].name')$'\n'
    url=$(echo "$page" | jq -r '.next')
done
repos=$(echo "$repos" | grep -E "^stata${VERSION}(-|$)")
[[ -z $repos ]] && { echo "No repositories matching stata${VERSION} in $ORG" >&2; exit 1; }

if [[ -z $DRYRUN ]]; then
    [[ -z $DOCKERHUB_USERNAME || -z $DOCKERHUB_TOKEN ]] && { echo "Set DOCKERHUB_USERNAME and DOCKERHUB_TOKEN" >&2; exit 1; }
    jwt=$(curl -fsS -H "Content-Type: application/json" \
        -d "{\"username\":\"$DOCKERHUB_USERNAME\",\"password\":\"$DOCKERHUB_TOKEN\"}" \
        https://hub.docker.com/v2/users/login | jq -r .token) || { echo "Login failed" >&2; exit 1; }
    echo "About to $ACTION in $ORG:"; echo "$repos" | sed 's/^/  /'
    read -p "Proceed? (y/N) " answer
    [[ $answer == y || $answer == Y ]] || exit 0
fi

ok=0; fail=0
for repo in $repos; do
    echo "$ACTION ${ORG}/${repo}"
    [[ -n $DRYRUN ]] && continue
    path=${ENDPOINT//\{org\}/$ORG}; path=${path//\{repo\}/$repo}
    code=$(curl -sS -o /dev/null -w '%{http_code}' -X POST -H "Authorization: JWT $jwt" "https://hub.docker.com$path")
    if [[ $code == 2* ]]; then ok=$((ok+1)); else echo "FAILED (HTTP $code): ${ORG}/${repo}" >&2; fail=$((fail+1)); fi
done

echo "Done: $ok ${ACTION}d, $fail failed."
[[ $fail -eq 0 ]]
