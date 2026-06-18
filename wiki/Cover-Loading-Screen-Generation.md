**Associated Files:** `releaseVerificationAndDeployment/generateLoadingScreen.py`, `releaseVerificationAndDeployment/loadingAssets/` (base image + font + licence), `.github/workflows/update-cover.yml`, `.github/workflows/deploy.yml`, `releaseVerificationAndDeployment/deploy.sh`, `Pictures/loading.jpg`

## Overview

The pack's cover image — `Pictures/loading.jpg`, used as the in-game `loadScreen` / `overviewPicture` and as the README banner — is **generated**, not hand-edited. The "WALDO'S MISSION PACK" title and the version number are rendered onto a text-free background image so the displayed version can never fall out of sync with the pack.

The version comes from a single source of truth: the `onLoadName` field in `description.ext` (e.g. `onLoadName = "Mission Pack v4.8.0";`). Bump the version there and the cover image follows automatically.

## How it stays in sync

| When | What happens |
|---|---|
| You push a change to `description.ext` on `main` | `update-cover.yml` regenerates `Pictures/loading.jpg` and commits it back to `main`. |
| A GitHub release is published | `deploy.sh` regenerates the image from the release tag before packing, so every released zip ships the correct version. |

Both paths call the same script, `generateLoadingScreen.py`, which draws the text with the bundled **Stardos Stencil** font (SIL Open Font License — see `loadingAssets/OFL.txt`).

The generator and its assets live in `releaseVerificationAndDeployment/loadingAssets/`. That folder is inside `releaseVerificationAndDeployment`, which every build already excludes (`notlist` in `config.json`), so the base image, font and script are **never shipped to mission makers** — only the finished `Pictures/loading.jpg` is.

## Regenerating the image by hand

```bash
pip install -r releaseVerificationAndDeployment/requirements.txt   # installs Pillow
# Render using the version in description.ext:
python3 releaseVerificationAndDeployment/generateLoadingScreen.py
# Or render an explicit version:
python3 releaseVerificationAndDeployment/generateLoadingScreen.py 4.8.0
```

Options:

| Argument | Purpose |
|---|---|
| `version` (positional) | Version to render, e.g. `4.8.0` or `v4.8.0`. Omit to parse it from `description.ext`. |
| `--base PATH` | Text-free background image (default `loadingAssets/loading_base.jpg`). |
| `--out PATH` | Output path (default `Pictures/loading.jpg`). |
| `--desc PATH` | `description.ext` to read when no version is passed. |
| `--font PATH` | Stencil font (default `loadingAssets/StardosStencil-Bold.ttf`). |

## Customising the look

The visual layout constants are grouped at the top of `generateLoadingScreen.py`:

- `TEXT_COLOR` — the blue used for both lines (RGB).
- `TITLE_SIZE` / `VERSION_SIZE` — font sizes in pixels.
- `TITLE_XY` / `VERSION_XY` — top-left anchor of each line of glyphs.
- `JPEG_QUALITY` — output quality.

To use your own background, replace `loadingAssets/loading_base.jpg` with a 1920x1080 image that has **no** title/version text in it (the script draws the text on top). To change the typeface, drop a new `.ttf` in `loadingAssets/`, update its licence file, and point `--font` (or `DEFAULT_FONT`) at it.

## See also

- [Mission Configuration Reference](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Configuration-Reference) — `onLoadName` and other `description.ext` fields.
- [Coding Standards](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Coding-Standards) — documentation standard followed here.
