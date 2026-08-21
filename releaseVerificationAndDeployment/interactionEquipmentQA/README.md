# In-engine interaction equipment QA

Static SQF validation cannot prove that Arma controls paint, scale, clip, focus,
or drag correctly. This disposable VR mission runs the repository's real
interaction code in the installed Arma 3 client and writes machine-readable
layout findings to the normal Arma RPT.

## Launch from Codex, Claude, or PowerShell

From the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_interaction_ui_qa.ps1 -Mode Interactive
```

Use `-Mode Active` to open the deterministic Wire Cut sample directly in its
active state for capture. Use `-Mode Automated` to open all ten procedures,
validate briefing and active states, drive each procedure through its real
success mechanics, and finish with the RPT marker shown below.

Use `-Mode Dialogue` for the dedicated Simple Dialogue subtitle and Advanced
Conversation response-panel layout. This beginner-facing sample verifies both
components together without requiring authored conversation data:

```text
WMP DIALOGUE UI QA COMPLETE: 0 finding(s) []
```

Pass `-Challenge repair` (or another built-in id) with `Interactive` or `Active`
to inspect a specific equipment face.

```text
WMP INTERACTION UI QA COMPLETE: 0 finding(s) []
```

For a focused Sequence review:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_interaction_ui_qa.ps1 -Mode Active -Challenge sequence
```

Confirm that the preparation pause, numbered/symbol playback caption, disabled
input during observation, `YOUR INPUT` transition, entered-signal transcript,
and one-use replay remain unambiguous without relying on lamp colour.

Select a curated gameplay profile with `-Difficulty easy`, `standard`, `hard`,
or `expert`. Run the complete 40-case mechanics and layout matrix with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\launch_interaction_ui_qa.ps1 -Mode Automated -AllDifficulties
```

Each RPT case is labelled `procedure/difficulty`. The matrix uses each
procedure's real selection, adjustment, timing, drag, and submission functions;
it does not inject solved Radio or Pressure values.

The launcher locates the installed Arma client from its registry entry, builds
`WMP_Interaction_UI_QA.VR` under the Arma installation's `Missions` directory,
and launches it with `-noBattlEye`, `-filePatching`, `-showScriptErrors`, and a
scripted mission bootstrap. BattlEye must remain disabled for this local,
generated file-patching test mission.

The launch writes outside the repository and opens a desktop application, so an
agent must request permission for that operation. It must not change or launch
the user's normal multiplayer profile or enable BattlEye for this workflow.

## Visual capture

Arma's scripted `screenshot` command does not include GUI controls. Capture the
actual Arma window externally:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\capture_interaction_ui.ps1 -OutputPath .\.qa\interaction-ui.png
```

The capture helper is per-monitor-DPI-aware and uses `PrintWindow`, so it records
the Arma window rather than whichever application happens to be in front. Keep
the resulting `.qa` captures disposable unless a reviewed screenshot is being
added deliberately to documentation.

Capture the briefing and active state of all ten procedures at one difficulty:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\run_interaction_ui_visual_qa.ps1 -Difficulty standard -State Both
```

This launches each disposable case with `-noBattlEye`, waits for the RPT
capture-ready marker, records the real Arma window, and closes only that QA
process. Screenshot review is an acceptance step: the runtime bounds validator
cannot detect poor hierarchy, weak contrast, overly bright controls, literal
escape text, or an animation cue that is too brief to follow.

## Acceptance checks

- Use the full `safeZoneX`, `safeZoneY`, `safeZoneW`, and `safeZoneH` extent.
  Arma's visible safe zone may extend well outside `0..1`; `0..1` is not a
  resolution- or UI-scale-independent viewport.
- Check the RPT for `Error in expression`, `Error position`, display
  serialization warnings, and every `WMP INTERACTION UI VALIDATION` line.
- Require zero runtime validator findings and zero SQF errors.
- Require each automated procedure to resolve successfully through its own
  input/state functions; the harness must never replace this with a direct call
  to the shared finish function.
- Inspect text legibility, hit-target size, focus, hover, disabled states,
  pointer capture, outside-control release, abort, and completion visually.
- Repeat at the documented aspect ratios and Arma UI scales. A single clean
  launch does not establish universal resolution support.
- Always use `-noBattlEye` for this generated local QA mission.

The source mission is `InteractionEquipmentQA.VR`; the build and launch scripts
copy only the current repository content needed for the isolated test.
