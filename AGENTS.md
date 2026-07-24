# WMP agent guidance

## Arma UI and interaction validation

Rendering-sensitive SQF work is not complete when lint passes. Use the disposable
VR mission documented in
`releaseVerificationAndDeployment/interactionEquipmentQA/README.md`.

- Always launch the generated local QA mission with `-noBattlEye`. Use the
  checked-in launcher, which supplies that flag; never remove it.
- Use `-Mode Interactive` for manual procedure cards and play, `-Mode Active
  -Challenge <id>` for a focused live display, and `-Mode Automated` for all
  ten procedures.
- Use `-Difficulty easy|standard|hard|expert` for a focused profile and
  `-Mode Automated -AllDifficulties` for the complete 40-case matrix.
- Automated QA must reach success through each procedure's real input/state
  functions. Directly assigning solved values or calling the common finish
  callback is not an acceptable mechanics test.
- Require `WMP INTERACTION UI QA COMPLETE: 0 finding(s) []` and no SQF errors in
  the RPT. A single clean resolution or UI scale does not prove universal
  layout support.
- Capture the real Arma window with `capture_interaction_ui.ps1`; Arma's own
  screenshot command excludes GUI controls.
- Run `run_interaction_ui_visual_qa.ps1` to capture all ten briefing and active
  equipment faces. Review the PNGs directly; zero geometry findings do not
  establish visual quality or readable animation timing.
- Inspect readability, phase transitions, disabled states, keyboard parity,
  pointer capture, release outside the original control, abort, and cleanup.
  Test the documented 4:3, 16:10, 16:9, and ultrawide configurations.
- Agent-driven launches write a disposable mission into the installed Arma
  directory and open a desktop application, so obtain the required permission.
