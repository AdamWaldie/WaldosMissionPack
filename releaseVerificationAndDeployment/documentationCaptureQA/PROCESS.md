# In-Engine Documentation Capture Process

This directory is maintainer tooling. It is not included in release archives.

## Purpose

Use this process when a feature's appearance or input behavior must be proven in Arma 3. Static SQF validation cannot prove that text fits, controls receive focus, safe-zone calculations are correct, or a procedure can be operated.

## Standard environment

- Arma 3 at 2560 x 1440 for the primary documentation set.
- `-noBattlEye`, `-showScriptErrors`, `-filePatching`, and an isolated profile.
- CBA, ACE, ZEN, and ACRE2 loaded for the full-pack environment.
- The generated QA mission is disposable. Source files in this directory remain authoritative.
- Capture the real Arma window externally. Arma's scripted screenshot command omits GUI controls.

## One-session workflow

1. Close Arma before rebuilding or staging the mission.
2. Build the documentation mission and wait for staging to finish before launching Arma. Launching while files are still copying can produce an empty or partially populated mission.
3. Start one Arma process and let `runCaptureBatch.sqf` move through all requested states.
4. The mission publishes a named ready marker for each state. The external controller waits for that marker, captures the Arma window, then acknowledges the state so the mission can continue.
5. Between states, close the active display, remove temporary handlers, clear notification channels, and reset input ownership. Do not rely on the next display to hide the previous one.
6. Review every image at its original resolution. Contact sheets are useful for coverage, but not for judging small text or clipping.
7. Re-capture only the affected states after a focused correction. Do not repeat the full batch when unchanged captures already pass review.

## Acceptance checks

For every captured state, confirm:

- The feature is recognisable without outside explanation.
- Headings, objectives, controls, warnings, and outcomes are readable at original resolution.
- Text and controls stay inside their panels with visible internal padding.
- Nothing overlaps protected controls or another WMP panel.
- Colour is reinforced by text, symbols, position, shape, or pattern.
- Interactive displays own mouse and keyboard focus while open.
- Closing, aborting, resetting, or advancing removes the display and its handlers.
- The RPT contains the expected ready/completion markers and no unexpected script errors.

## Failure patterns found during this rebuild

- Treating `0..1` as the visible viewport made interfaces tiny or misplaced. Layout must use `safeZoneX`, `safeZoneY`, `safeZoneW`, and `safeZoneH`.
- Hidden controls parked off-screen polluted automatic bounds and shrank otherwise correct displays. Exclude utility and hidden controls from visible-content fitting.
- Enlarging a container without reflowing its children created huge empty areas and over-sized buttons. Scale the designed canvas uniformly, then fit the card to the safe zone.
- A generic `hint` competed with branded panels and could outlive the feature that created it. Named WMP notification channels allow exact replacement and dismissal.
- Briefings that technically fit were still too small to read. Review typography at the final capture resolution, not only runtime overflow findings.
- Launching one Arma process per screenshot was slow and introduced more staging failures. The state/acknowledgement batch protocol is both faster and easier to audit.
- Reading an array of RPT lines with a single regular-expression match silently missed markers. Join the current tail before matching.
- Steam can detach the process started by the launcher. Attach capture monitoring to the actual Arma process ID, not the short-lived launcher process.

## Evidence and retention

The `.qa` directory contains disposable RPTs, profiles, raw captures, and contact sheets. Copy only reviewed representative images into `wiki/images`. Keep the source mission, launchers, capture scripts, and this process document in `releaseVerificationAndDeployment` so future coding agents can reproduce the run.

The release builder explicitly excludes both `releaseVerificationAndDeployment` and `wiki`; automated tests enforce that boundary.
