#!/usr/bin/env bash

set -eux

PRODUCT="YOUR_PRODUCT_NAME"  # TODO: replace, i.e: opensearch
UPSTREAM_GH_PROJECT="https://github.com/THE_PROJECT_OF_THE_PRODUCT"  # TODO: replace, i.e: https://github.com/opensearch-project
LP_USER_NAME="YOUR_LP_USER_NAME"  # TODO: replace, i.e: medib
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

    # clone main branch of upstream repo
    local_repo="$(echo "${repo}" | awk '{print tolower($0)}')"
    if [[ ${local_repo} != ${PRODUCT}* ]]; then
        local_repo="${PRODUCT}-${local_repo}"
    fi

    git clone --single-branch --branch main "${UPSTREAM_GH_PROJECT}/${repo}.git" "${local_repo}"
    pushd "${local_repo}" || exit 1

    # fetch all tags
    git pull
    git fetch --all --tags

    # add launchpad remote for push
    git remote add launchpad "git+ssh://${LP_USER_NAME}@git.launchpad.net/soss/+source/${local_repo}"

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

        # delete default main remote LP branch
        git push launchpad --delete main || true
    done

    popd || exit 1
    popd || exit 1
done
