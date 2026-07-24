# WMP in-engine release audit process

This is the canonical process for validating a WMP feature branch before a
release. Static validation remains mandatory, but it cannot establish Arma
locality, JIP, interaction rendering, mod integration or multiplayer rules.

## 1. Freeze the source under test

1. Confirm the intended branch and review every dirty file.
2. Preserve validated work in a commit before synchronising the branch with
   current `main`.
3. Never build the audit from a different worktree or from a release ZIP whose
   source commit is unknown.
4. Record the source commit, Arma build, mod profile and exact test manifest in
   the evidence report.

## 2. Run static gates

Run the SQF validator, config checker, interaction UI architecture checker,
audit unit tests and Git whitespace check. Any failure blocks Arma testing.

## 3. Stage the real mission

`build_full_arma_audit.py` copies the checked-in `FullArmaAudit.VR` mission,
the current `MissionScripts`, `Pictures`, economy configuration and manifest to
an unpacked disposable mission. The canonical release gate uses
`launch_full_arma_dedicated_audit.ps1`, which stages it under `MPMissions` and
loads it through the normal mission lifecycle:

`description.ext -> CfgFunctions -> initServer.sqf / init.sqf / initPlayerLocal.sqf`

The fast `launch_full_arma_audit.ps1` scripted mode exists only to validate the
audit kernel itself. It is not evidence that the real mission starts correctly.

BattlEye must always remain disabled for generated, file-patched QA missions.

## 4. Execute profiles in order

1. `core` with one client and CBA/ACE/ZEN/ACRE2.
2. `economy` with one client, then server plus two clients.
3. `ew` once with ACRE2 and once with TFAR.
4. `interactions` full 40-case mechanics matrix and visual matrix.
5. `party` with two clients, four clients, then a targeted fifth JIP spectator.
6. `all` as the final combined smoke and cleanup run.

Use isolated server/client profiles and distinct ports. Do not reuse a normal
player profile. Each run must close only the processes it started.

## 5. Review evidence

- Require every expected case ID from `audit_manifest.json`.
- Require zero structured failures and zero unexpected RPT expression, missing
  script, undefined-variable or serialization errors.
- Review externally captured windows for clipping, text fit, hierarchy,
  colour-independent meaning and transition timing.
- Inspect public namespaces from a spectator for hidden card/dice leakage.
- Record observed FPS and bandwidth as environment-specific observations, not
  universal performance claims.

## 6. Fix and retest

For every reproducible first-party defect:

1. Save its case ID, RPT excerpt, screenshot and reproduction profile.
2. Fix the smallest behavior-preserving surface.
3. Rerun the focused case.
4. Rerun its complete subsystem suite.
5. Rerun the final combined smoke if authority, cleanup or shared UI changed.

Only genuine Arma or mod limitations may remain, and each must have a verified
reproduction and mission-maker mitigation.

## 7. Release sign-off

The audit report must identify the source commit, exact passed matrix, mod
versions, resolutions/UI scales, dedicated-server/client counts, reviewed
screenshots, all fixes, and any engine limitations. Update the PR body and wiki
only with results actually observed in Arma.
