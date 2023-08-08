#!/usr/bin/env bash

declare -a VERSIONS=("2.9.0" "2.8.0")

pushd ../..

remote_url="distributionUrl=https\\\:\/\/services.gradle.org\/distributions"
jfrog_url="distributionUrl=https\\\:\/\/canonical.jfrog.io\/ui\/native\/dataplatform-generic-stable-local\/gradle"

find . -maxdepth 1 -name "opensearch*" -type d | awk '{print $1}' | while read -r project; do
    pushd "${project}" || exit 1

    if [[ "${project}" == *python ]]; then
        continue
    fi

    if [[ "${project}" == *opensearch-performance-analyzer-rca ]]; then
        git checkout main
        sed -i -e "s/^${remote_url}\+/${jfrog_url}/g" gradle/wrapper/gradle-wrapper.properties
        git add .
        git commit -m "changed gradle distro url"
        git push launchpad

        popd || exit 1
        continue
    fi

    for version in "${VERSIONS[@]}"; do
        git checkout "lp-${version}"

        gradle_wrapper="gradle/wrapper/gradle-wrapper.properties"
        if [[ "${project}" == *notifications* ]]; then
            gradle_wrapper="notifications/${gradle_wrapper}"
        fi

        sed -i -e "s/^${remote_url}\+/${jfrog_url}/g" "${gradle_wrapper}"

        git add .
        git commit -m "changed gradle distro url"
        git push launchpad

        version_tag="$(git tag -l --sort=version:refname "lp-v${version}.*" | tail -1)"
        git tag "${version_tag}" --force
        git push launchpad "${version_tag}" --force

    done

    popd || exit 1

done
