#!/usr/bin/env bash

set -eux

declare -a VERSIONS=("2.9.0" "2.8.0")
declare -a REPOS=(
    opensearch-build
    OpenSearch
    common-utils
    job-scheduler
    k-NN
    geospatial
    security
    cross-cluster-replication
    ml-commons
    neural-search
    notifications
    observability
    reporting
    sql
    asynchronous-search
    anomaly-detection
    alerting
    security-analytics
    index-management
    performance-analyzer
)
LP_SOSS_REMOTE="git+ssh://medib@git.launchpad.net/soss/+source"
LP_PUBLIC_REMOTE="git+ssh://medib@git.launchpad.net/~medib/+git" # opensearch-project-components

for repo in "${REPOS[@]}"; do
    echo "${repo}"

    pushd ../.. || exit 1

    # clone main branch of upstream repo
    local_repo="$(echo "${repo}" | awk '{print tolower($0)}')"
    if [[ ${local_repo} != opensearch* ]]; then
        local_repo="opensearch-${local_repo}"
    fi

    [ -d "${local_repo}" ] || git clone --single-branch --branch main "https://github.com/opensearch-project/${repo}.git" "${local_repo}"
    pushd "${local_repo}" || exit 1

    # fetch all tags
    git pull
    git fetch --all --tags

    # add launchpad remote for push
    lp_remote="${LP_PUBLIC_REMOTE}"
    if [[ "${repo}" == "opensearch-build" ]]; then
        lp_remote="${LP_SOSS_REMOTE}"
    fi
    git remote add launchpad "${lp_remote}/${local_repo}"

    # TODO: add case of opensearch-performance-analyzer-rca:
      # - pull branch on rca (not tag based)
      # - checkout new lp-version branch out of it
      # - change branch name on build.gradle of performance-analyzer (add lp- prefix)

    for version in "${VERSIONS[@]}"; do
        GH_BRANCH="${version}"
        LP_BRANCH="lp-${version}"

        # add remote version branch
        # git remote set-branches --add "origin" "${GH_BRANCH}"

        # get version / release tag and associated commit
        version_tag="$(git tag -l --sort=version:refname "${version}.*" | tail -1)"
        gh_release_commit="$(git show-ref -s "${version_tag}")"

        # checkout version branch
        git checkout -b "${GH_BRANCH}" "${gh_release_commit}"

        # create lp branch based on the version branch
        git checkout -b "${LP_BRANCH}"

        # fetch current version's latest tag and tag current
        lp_tag_name="lp-v${version_tag}"
        git tag -a "${lp_tag_name}" "${gh_release_commit}" -m "tagging commit with tag: ${lp_tag_name}" --force

        # push lp version branch to LP
        git push --set-upstream launchpad "${LP_BRANCH}"
        git push launchpad --delete "${lp_tag_name}" || true
        git push launchpad "${lp_tag_name}"

        # delete default main remote LP branch
        git push launchpad --delete main || true
    done

    popd || exit 1
    popd || exit 1
done

# ------------------------

# performance analyzer RCA, and faiss and nmslib
declare -a ALTERNATE_REPOS=(
    https://github.com/opensearch-project/performance-analyzer-rca.git
    https://github.com/facebookresearch/faiss.git
    https://github.com/nmslib/nmslib.git
)
for repo in "${ALTERNATE_REPOS[@]}"; do
    echo "${repo}"

    pushd ../.. || exit 1

    local_repo="$(echo "${repo}" | awk '{print tolower($0)}' | awk -F/ '{print $NF}' | awk -F. '{print $1}')"
    if [[ ${repo} == *opensearch-project* ]]; then
        local_repo="opensearch-${local_repo}"
    else
        local_repo="python-${local_repo}"
    fi

    main_branch="main"
    if [[ "${repo}" == *nmslib* ]]; then
        main_branch="master"
    fi
    git clone --single-branch --branch "${main_branch}" "${repo}" "${local_repo}"
    pushd "${local_repo}" || exit 1

    # fetch all tags
    git pull
    git fetch --all --tags

    # add launchpad remote for push
    git remote add launchpad "${LP_PUBLIC_REMOTE}/${local_repo}"

    # push lp version branch to LP
    git push -f --set-upstream launchpad "${main_branch}"

    # rename default main branch created by soss
    git push launchpad --delete old_main || true

    popd || exit 1
    popd || exit 1
done
