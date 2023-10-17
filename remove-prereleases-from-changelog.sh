#!/bin/bash

# This script removes all prerelease lines from the changelog file.

# Usage: ./remove-prereleases-from-changelog.sh

current=$(cat CHANGELOG.md | grep -E '## [0-9]+\.[0-9]+\.[0-9]+(.*)' | head -n 1)
prerelease=$(echo $current | grep -E '## [0-9]+\.[0-9]+\.[0-9]+-(.+)')

if [ -z "$prerelease" ]; then
    sed -E 's:##\ [0-9]+\.[0-9]+\.[0-9]+-.+::g' CHANGELOG.md | sed 's:[\ ]*- Graduate package to a stable release.*::g' | cat -s > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md
fi
