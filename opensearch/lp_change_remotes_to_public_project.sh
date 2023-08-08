#!/usr/bin/env bash

pushd ../..

find . -maxdepth 1 \( -name "opensearch*" -o -name "python-*" \) -type d | awk '{print $1}' | while read -r project; do
    pushd "${project}" || exit 1

    if [[ "${project}" == *opensearch-build ]]; then
        continue
    fi

    git remote remove launchpad
    git remote add launchpad "https://git.launchpad.net/~medib/opensearch-project-components/+git/${project#./}"

    popd || exit 1

done
