#!/bin/bash
# Archive (make read-only) all Docker Hub repositories of one Stata version,
# e.g. stata17, stata17-mp, stata17-se-i, ...
#
# Docker Hub has no documented archive API. The repository status codes
# (active=1, archived=6) are taken from the Hub web UI; setting "status" via
# PATCH /v2/repositories/{org}/{repo}/ was verified to archive a repository.
# If Docker changes this, override with ARCHIVE_METHOD / ARCHIVE_PATH.
#
# Requires: curl, jq; DOCKERHUB_USERNAME and DOCKERHUB_TOKEN in the environment.
# The token must have "Read, Write, Delete" permissions (a Read/Write token gets
# HTTP 403 "insufficient scope"), and belong to a user with admin rights in the org.

ORG=${ORG:-sscng}
VERSION=
DRYRUN=
UNARCHIVE=
STATUS_ACTIVE=1
STATUS_ARCHIVED=6
# request that sets the status; {org} and {repo} are substituted
ARCHIVE_METHOD=${ARCHIVE_METHOD:-PATCH}
[[ -z $ARCHIVE_PATH ]] && ARCHIVE_PATH='/v2/repositories/{org}/{repo}/'

usage() {
cat << EOT

$0 -v version [-o org] [-n] [-u]

Archives all repositories $ORG/stata<version>[-variant] on Docker Hub.
  -v   Stata version, required (17, 18, 18_5, ...); 18 does not match 18_5
  -o   Docker Hub organization (default: $ORG)
  -n   dry run: only list the repositories and their current status
  -u   unarchive instead of archive
  -h   this help
Environment: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN;
  ARCHIVE_METHOD, ARCHIVE_PATH (current: $ARCHIVE_METHOD $ARCHIVE_PATH)
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

ACTION=archive; TARGET=$STATUS_ARCHIVED
[[ -n $UNARCHIVE ]] && { ACTION=unarchive; TARGET=$STATUS_ACTIVE; }

# current status of a repository (public endpoint)
repo_status() {
    curl -fsS "https://hub.docker.com/v2/repositories/${ORG}/$1/" | jq -r '.status'
}

# send {"status": $3} to repository $2 using request spec $1 ("METHOD /path")
set_status() {
    local method=${1%% *} path=${1#* }
    path=${path//\{org\}/$ORG}; path=${path//\{repo\}/$2}
    curl -sS -o "$RESP" -w '%{http_code}' -X "$method" \
        -H "Authorization: Bearer $jwt" -H "Content-Type: application/json" \
        -d "{\"status\":$3}" "https://hub.docker.com$path"
}

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

if [[ -n $DRYRUN ]]; then
    for repo in $repos; do echo "${ORG}/${repo}: status $(repo_status $repo)"; done
    exit 0
fi

[[ -z $DOCKERHUB_USERNAME || -z $DOCKERHUB_TOKEN ]] && { echo "Set DOCKERHUB_USERNAME and DOCKERHUB_TOKEN" >&2; exit 1; }
jwt=$(curl -fsS -H "Content-Type: application/json" \
    -d "$(jq -n --arg u "$DOCKERHUB_USERNAME" --arg p "$DOCKERHUB_TOKEN" '{username:$u,password:$p}')" \
    https://hub.docker.com/v2/users/login | jq -r '.token // empty')
[[ -z $jwt ]] && { echo "Login failed" >&2; exit 1; }
RESP=$(mktemp); trap 'rm -f "$RESP"' EXIT

echo "About to $ACTION in $ORG using $ARCHIVE_METHOD $ARCHIVE_PATH:"; echo "$repos" | sed 's/^/  /'
read -p "Proceed? (y/N) " answer
[[ $answer == y || $answer == Y ]] || exit 0

ok=0; skip=0; fail=0
for repo in $repos; do
    if [[ $(repo_status $repo) == $TARGET ]]; then
        echo "SKIP (already ${ACTION}d): ${ORG}/${repo}"; skip=$((skip+1)); continue
    fi
    echo "$ACTION ${ORG}/${repo}"
    code=$(set_status "$ARCHIVE_METHOD $ARCHIVE_PATH" "$repo" "$TARGET")
    # a 2xx that silently ignores the field leaves the status unchanged, so check
    if [[ $code == 2* && $(repo_status $repo) == $TARGET ]]; then
        ok=$((ok+1))
    else
        echo "FAILED (HTTP $code, status now $(repo_status $repo)): ${ORG}/${repo} $(head -c 300 "$RESP")" >&2
        fail=$((fail+1))
    fi
done

echo "Done: $ok ${ACTION}d, $skip skipped, $fail failed."
[[ $fail -eq 0 ]]
