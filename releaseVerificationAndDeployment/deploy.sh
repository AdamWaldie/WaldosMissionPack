#!/bin/bash

set -e

VERSION_TAG=$*
# The release tag is authoritative. Update only this workflow checkout before packaging so the
# shipped mission title and generated cover always match without requiring a pre-release commit.
python3 releaseVerificationAndDeployment/set_description_version.py "${VERSION_TAG}"

mkdir release/

sed -i "s/#define VERSION.*/#define VERSION \"${VERSION_TAG}\"/" releaseVerificationAndDeployment/buildVersion.hpp
sed -i "s/DevBuild/${VERSION_TAG}/" releaseVerificationAndDeployment/config.json

# Regenerate the cover image so the packed loading.jpg matches the release tag
python3 releaseVerificationAndDeployment/generateLoadingScreen.py "${VERSION_TAG}"

python3 releaseVerificationAndDeployment/build.py --deploy


# Special Builds
#python3 releaseVerificationAndDeployment/build.py --build config_ExemplarMission.json --deploy
python3 releaseVerificationAndDeployment/build.py --build config_unitInsignias.json --deploy
#python3 releaseVerificationAndDeployment/build.py --build config_claudeSkill.json --deploy

# Headless Client Kit - server-hosting scripts/examples for actually connecting a headless client,
# deliberately excluded from the main WMP pack's own include list (config.json). Produced on every
# release as its own artifact so a server admin can grab it without the rest of the pack.
python3 releaseVerificationAndDeployment/build.py --build config_headlessClientKit.json --deploy

# Only the claude.ai-upload-ready shape ships now (skill folder at the zip root — what claude.ai's
# "Upload skill" dialog and the Skills API require, and also what a mission-project drop-in should
# use, moving the extracted folder under .claude/skills/ by hand). The prefixed
# ".claude/skills/mission-pack-config/"-rooted zip (config_claudeSkill.json) remains available for
# a manual build but is not produced by this script, same as the Exemplar build above.
python3 releaseVerificationAndDeployment/package_claude_skill_upload.py "${VERSION_TAG}" release

sed -i "s/DEVBUILD/${VERSION_TAG}/g" WMP_Compositions/*/header.sqe

# Make a patch release
set +e # allow fail
PREV_TAG=$(git describe --abbrev=0 --tags `git rev-list --tags --skip=1 --max-count=1`)
echo "Creating patch build for ${PREV_TAG} to ${VERSION_TAG}"
git diff --name-only ${PREV_TAG} ${VERSION_TAG} > pre_changed_file_list.txt
python3 releaseVerificationAndDeployment/release_file_list.py \
  pre_changed_file_list.txt changed_file_list.txt \
  --config releaseVerificationAndDeployment/config.json
zip release/WMP_PATCH_v${PREV_TAG}_to_v${VERSION_TAG}.zip -@ < changed_file_list.txt
set -e

# Pack Compositions
zip release/WMP_Compositions-${VERSION_TAG}.zip -r WMP_Compositions
