#!/usr/bin/env bash

set -eux

PRODUCT="YOUR_PRODUCT_NAME"  # TODO: replace, i.e: opensearch
declare -a VERSIONS=(  # TODO: replace
    # major_minor_version_1 (i.e 2.8)
    # major_minor_version_2 (i.e 2.9)
)
declare -a REPOS=(  # belong to the UPSTREAM_GH_PROJECT -- # TODO: replace
    # upstream_github_repo_1 (i.e k-NN)
    # upstream_github_repo_2 (i.e performance_analyzer)
)


for repo in "${REPOS[@]}"; do
    echo "${repo}"

    pushd ../ || exit 1

    # locate the locate repo
    local_repo="$(echo "${repo}" | awk '{print tolower($0)}')"
    if [[ ${local_repo} != ${PRODUCT}* ]]; then
        local_repo="${PRODUCT}-${local_repo}"
    fi
    pushd "${local_repo}" || exit 1

    # fetch all tags
    git pull
    git fetch --all --tags

    for version in "${VERSIONS[@]}"; do
        GH_BRANCH="${version}"
        LP_BRANCH="lp-${version}"

        # get version / release tag and associated commit
        version_tag="$(git tag -l --sort=version:refname "${version}.*" | tail -1)"
        gh_release_commit="$(git show-ref -s "${version_tag}")"

        # checkout version branch
        git checkout -b "${GH_BRANCH}" "${gh_release_commit}"

        # create lp branch based on the version branch
        git checkout -b "${LP_BRANCH}"

        # fetch current version's latest tag and tag current
        lp_tag_name="lp-${version_tag}"
        git tag -a "${lp_tag_name}" "${gh_release_commit}" -m "tagging commit with tag: ${lp_tag_name}" --force

        # push lp version branch to LP
        git push --set-upstream launchpad "${LP_BRANCH}"
        git push launchpad --delete "${lp_tag_name}" || true
        git push launchpad "${lp_tag_name}"
    done

    popd || exit 1
    popd || exit 1
done
