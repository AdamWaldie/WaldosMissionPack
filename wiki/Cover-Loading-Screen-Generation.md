# Cover and Loading-Screen Generation

> **Use this page when:** you need to regenerate, customize, or troubleshoot the versioned mission artwork.

**Associated Files:** `releaseVerificationAndDeployment/generateLoadingScreen.py`, `releaseVerificationAndDeployment/loadingAssets/` (base image + font + licence), `.github/workflows/update-cover.yml`, `.github/workflows/deploy.yml`, `releaseVerificationAndDeployment/deploy.sh`, `Pictures/loading.jpg`

## Overview

The pack generates `Pictures/loading.jpg` for the in-game `loadScreen`, `overviewPicture` and README banner. The script draws the "WALDO'S MISSION PACK" title and version number onto a text-free background, keeping the displayed version in sync with the pack.

The version comes from the `onLoadName` field in `description.ext`. When you change that title for a release, regenerate the cover image so the two match.

## How it stays in sync

| When | What happens |
|---|---|
| You push a change to `description.ext` on `main` | `update-cover.yml` regenerates `Pictures/loading.jpg` and commits it back to `main`. |
| A GitHub release is published | `deploy.sh` regenerates the image from the release tag before packing, so every released zip ships the correct version. |

Both paths call `generateLoadingScreen.py`. It draws the text with the bundled **Stardos Stencil** font (SIL Open Font License; see `loadingAssets/OFL.txt`).

The generator and its assets live in `releaseVerificationAndDeployment/loadingAssets/`. Every build excludes that folder through `notlist` in `config.json`. Mission makers receive the finished `Pictures/loading.jpg` without the base image, font or generator.

## Regenerating the image by hand

```bash
pip install -r releaseVerificationAndDeployment/requirements.txt   # installs Pillow
# Render using the version in description.ext:
python3 releaseVerificationAndDeployment/generateLoadingScreen.py
# Or render an explicit version:
python3 releaseVerificationAndDeployment/generateLoadingScreen.py 4.9.2
```

Options (these are generator command-line inputs, not WMP mission settings):

| Argument | Type and default | Purpose |
|---|---|---|
| `version` (positional) | String; omitted by default | Version to render, such as `4.9.2` or `v4.9.2`. Omit it to read `description.ext`. |
| `--base PATH` | File path String; bundled `loadingAssets/loading_base.jpg` | Text-free background image. |
| `--out PATH` | File path String; `Pictures/loading.jpg` | Output JPEG. |
| `--desc PATH` | File path String; root `description.ext` | Mission description to read when no version is passed. |
| `--font PATH` | File path String; bundled `loadingAssets/StardosStencil-Bold.ttf` | Stencil font. |
| `--print-version` | Flag Boolean; off by default | Print the resolved version and exit without drawing. |

The generator writes the JPEG at `--out` and exits non-zero when an input cannot be
resolved. `--print-version` only prints text; it does not change an image. The
generator runs on the packaging machine, so it has no Arma locality or JIP behaviour.

## Customising the look

The visual layout constants are grouped at the top of `generateLoadingScreen.py`:

- `TEXT_COLOR`: the blue used for both lines (RGB).
- `TITLE_SIZE` / `VERSION_SIZE`: font sizes in pixels.
- `TITLE_XY` / `VERSION_XY`: top-left anchor of each line of glyphs.
- `JPEG_QUALITY`: output quality.

To use your own background, replace `loadingAssets/loading_base.jpg` with a 1920x1080 image that has **no** title/version text in it (the script draws the text on top). To change the typeface, drop a new `.ttf` in `loadingAssets/`, update its licence file, and point `--font` (or `DEFAULT_FONT`) at it.

## If the cover shows the wrong version

Check the version in `description.ext`, regenerate `Pictures/loading.jpg`, then package that new image with the mission. Rendering an explicit version number overrides the value read from `description.ext` for that run only.

## See also

- [Mission Configuration Reference](Mission-Configuration-Reference): `onLoadName` and other `description.ext` fields.
- [Coding Standards](Coding-Standards): repository documentation conventions.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
