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

### Closed-game staging rule

The audit has two strictly separated phases:

1. **Arma closed:** edit source, run validators, rebuild and stage the mission.
2. **Arma open:** play, observe, capture screenshots and monitor the RPT. Do not edit, rebuild,
   copy or refresh mission files while any audit client or server is running.

Close every audit process before returning to phase 1. Arma holds mission configuration and
included files open, and refreshing a live mission can leave a partial folder or mix cached and
current scripts. Both launchers refuse to stage while an Arma process is already running.

`build_pr_review_audit.py` is the canonical builder. It reads the release allowlist from
`config.json`, stages every listed root, overlays the proven unbinarized `FullArmaAudit.VR`
scenario and appends isolated audit hooks to the real startup files. After the pack reports ready,
the server builds the walkable range with production setup functions and publishes it for JIP.
It does not maintain a
hand-picked approximation of the pack. Routine testing uses `launch_pr_review_audit.ps1`: select
Virtual Reality, choose WMP FULL PACK PR AUDIT, press Play, pick a slot and press OK. The launch uses
CBA, ACE, ZEN and ACRE2, disables BattlEye and defaults to 3840×2160.

The staged mission loads the normal mission lifecycle:

`description.ext -> CfgFunctions -> initServer.sqf / init.sqf / initPlayerLocal.sqf`

Manual mode is the release-review default. It loads the whole development pack but does not run
the old state-mutating audit cases. `-Mode Automated` is opt-in and disposable. The generated
Eden `WMP_FPA.VR` mission and its launchers remain experimental and are not evidence until that
mission independently passes the hosted load gate; only its range setup scripts are reused.

BattlEye must always remain disabled for generated QA missions. The full audit
mission is self-contained and deliberately does not enable file patching; this
avoids multiplayer signature/rejection differences and ensures the staged
mission is the exact runtime source.
The checked-in base mission must remain independently loadable. Its purpose is a stable scenario
shell; the builder deliberately supplies the current release files so feature testing never uses
a stale embedded copy.

### Coding-agent build contract

Any coding agent must use `build_pr_review_audit.py` or `launch_pr_review_audit.ps1`. The builder
must continue to derive its inputs from `config.json`; adding a new release root therefore adds it
to the audit automatically. Tests compare staged source trees byte-for-byte and require all three
real pack entry points plus their audit hooks. Manual mode must not execute `runServerAudit.sqf`,
`runClientAudit.sqf`, temporary AI tests, SafeStart transitions or destructive state changes.
Automated mode is disposable and explicit.

## 4. Execute profiles in order

1. `core` with one host and CBA/ACE/ZEN for radio-independent smoke tests.
2. `economy` with one client, then server plus two clients.
3. `ew` once with ACRE2 and once with TFAR.
4. `interactions` full 40-case mechanics matrix and visual matrix.
5. `party` with two real clients, four real clients, then a targeted fifth JIP spectator.
6. `all` with ACRE2 (the launcher default) as the final combined smoke and cleanup run.

The `ew` and `all` suites require either the `acre` or `tfar` profile. Startup
also verifies the corresponding loaded patch, so a mislabeled launcher profile
cannot silently produce a false pass.

Use isolated server/client profiles and distinct ports. Do not reuse a normal
player profile. Each run must close only the processes it started.

## 5. Review evidence

- Require every expected case ID from `audit_manifest.json`.
- Require zero structured failures and zero unexpected RPT expression, missing
  script, undefined-variable or serialization errors.
- Require one complete `[WMP DIAG]` run with matching server/client run IDs,
  zero `ERROR` states, and a client report from every connected player.
- Review externally captured windows for clipping, text fit, hierarchy,
  colour-independent meaning and transition timing.
- Inspect public namespaces from a spectator for hidden card/dice leakage.
- Record observed FPS and bandwidth as environment-specific observations, not
  universal performance claims.

## 6. Fix and retest

For every reproducible first-party defect:

1. Save its case ID, RPT excerpt, screenshot and reproduction profile.
2. Close every Arma client and server from the run.
3. Fix the smallest behavior-preserving surface.
4. Run static validation and stage one complete, coherent mission copy.
5. Rerun the focused case.
6. Rerun its complete subsystem suite.
7. Rerun the final combined smoke if authority, cleanup or shared UI changed.

Only genuine Arma or mod limitations may remain, and each must have a verified
reproduction and mission-maker mitigation.

## Recurring failure classes and mandatory prevention

These are release gates, not optional review advice:

- **Delimiter-valid but engine-invalid SQF:** a bracket checker cannot prove an
  SQF command exists. Known invalid runtime tokens are rejected by the repository
  validator. Any new dynamically drawn control path must also compile and open in
  Arma with `-showScriptErrors`; a forced success callback is not a rendering test.
- **Assertions outside genuine gameplay context:** ACE and vanilla conditions
  that include range, life state, ownership, locality or current display state
  must be exercised with a real actor in that context. Registration flags and
  calls made from the other side of the test range are not acceptance evidence.
- **Display ownership collisions:** a subsystem must not create a modal child
  display merely to draw a prompt over Zeus or gameplay. Overlay controls record
  their parent, baseline and owned controls, fit only their own controls and
  delete only their own controls. Persistent systems have one named screen
  region and one visual owner.
- **Duplicate notification channels:** when a WMP panel is present, the same
  state must not also use `hint`, `hintSilent`, chat or another panel. Normal
  status, warnings, failure and restoration stay in the owning panel; fallback
  hints are allowed only when that panel cannot be created.
- **Startup races:** gameplay authority may start immediately, but transient UI,
  diagnostics and visual test fixtures wait for `WALDO_INIT_COMPLETE`. Audit
  stations begin dormant or outside their effect radius and activate when the
  tester enters the station.
- **Safe-zone without content padding:** fitting an outer card inside the screen
  is insufficient. Every drawn screen needs a visible-safe outer rectangle, a
  panel rectangle, a separately inset content rectangle and measured text fit.
- **Staged mission drift:** the checked-in mission copy must byte-match current
  `MissionScripts`. The disposable build uses the full release entry points and
  changes only documented QA inputs, such as the deterministic loadout fixture.
- **Optional-mod fixtures in a required profile:** audit configuration may only
  reference classes available in its declared mod profile. Optional RHS, TFAR or
  ACRE paths are tested in their own profiles and cannot silently contaminate the
  core fixture.
- **Static pass mistaken for release sign-off:** Python/unit/SQF/config/whitespace
  gates run before Arma, but final status remains `RETEST REQUIRED` until the
  focused runtime path, RPT and representative external capture pass.
- **Action ownership violations:** discoverable, single-purpose stations such
  as Economy terminals, loadout save/crate stations and interaction equipment
  may expose linked ACE and vanilla actions simultaneously. Complex nested
  systems such as MHQ, VVD and Quartermaster use ACE when available and install
  vanilla actions only as fallback. Party tables retain their existing
  discoverable interaction model. Every route calls the same guarded gameplay
  function, records only the entries it owns and must preserve entries owned by
  every other feature. `removeAllActions` is forbidden in first-party scripts.

## 7. Release sign-off

The audit report must identify the source commit, exact passed matrix, mod
versions, resolutions/UI scales, dedicated-server/client counts, reviewed
screenshots, all fixes, and any engine limitations. Update the PR body and wiki
only with results actually observed in Arma.
