#!/bin/bash

set -e

VERSION_TAG=$*

mkdir release/

sed -i "s/#define VERSION.*/#define VERSION \"${VERSION_TAG}\"/" releaseVerificationAndDeployment/buildVersion.hpp
sed -i "s/DevBuild/${VERSION_TAG}/" releaseVerificationAndDeployment/config.json

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
