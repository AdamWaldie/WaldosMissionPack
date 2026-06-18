#!/bin/bash

set -e

VERSION_TAG=$*

# Guard (Waldos Mission Pack release ordering):
# The visible cover (Pictures/loading.jpg, rendered from description.ext's onLoadName) must
# already match this release tag before we pack. If it doesn't, the version was not bumped on
# main first, so update-cover.yml has not refreshed the README/committed cover for this tag.
DESC_VERSION=$(python3 releaseVerificationAndDeployment/generateLoadingScreen.py --print-version)
TAG_VERSION=${VERSION_TAG#v}      # strip an optional leading "v"
TAG_CORE=${TAG_VERSION%%-*}       # drop a prerelease suffix (e.g. 4.8.0-rc1 -> 4.8.0)
if [ "$DESC_VERSION" != "$TAG_CORE" ]; then
  echo "ERROR: description.ext version (v${DESC_VERSION}) does not match release tag (${VERSION_TAG})." >&2
  echo "Bump onLoadName in description.ext to v${TAG_CORE} and let update-cover.yml refresh" >&2
  echo "Pictures/loading.jpg on main before publishing this release." >&2
  exit 1
fi

mkdir release/

sed -i "s/#define VERSION.*/#define VERSION \"${VERSION_TAG}\"/" releaseVerificationAndDeployment/buildVersion.hpp
sed -i "s/DevBuild/${VERSION_TAG}/" releaseVerificationAndDeployment/config.json

# Regenerate the cover image so the packed loading.jpg matches the release tag
python3 releaseVerificationAndDeployment/generateLoadingScreen.py "${VERSION_TAG}"

python3 releaseVerificationAndDeployment/build.py --deploy


# Special Builds
#python3 releaseVerificationAndDeployment/build.py --build config_ExemplarMission.json --deploy
python3 releaseVerificationAndDeployment/build.py --build config_unitInsignias.json --deploy

sed -i "s/DEVBUILD/${VERSION_TAG}/g" WMP_Compositions/*/header.sqe

# Make a patch release
set +e # allow fail
PREV_TAG=$(git describe --abbrev=0 --tags `git rev-list --tags --skip=1 --max-count=1`)
echo "Creating patch build for ${PREV_TAG} to ${VERSION_TAG}"
git diff --name-only ${PREV_TAG} ${VERSION_TAG} > pre_changed_file_list.txt
sed '/releaseVerificationAndDeployment/d;/WMP_Compositions/d;/^\.\(.*\)/d' pre_changed_file_list.txt > changed_file_list.txt
zip release/WMP_PATCH_v${PREV_TAG}_to_v${VERSION_TAG}.zip -@ < changed_file_list.txt
set -e

# Pack Compositions
zip release/WMP_Compositions-${VERSION_TAG}.zip -r WMP_Compositions
