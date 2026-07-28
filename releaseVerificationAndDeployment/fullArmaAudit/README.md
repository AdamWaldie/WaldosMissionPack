# WMP PR review audit mission

`FullArmaAudit.VR` is the canonical base mission for feature testing. It deliberately keeps the
small, unbinarized `version=12` VR scenario that Arma has proven able to host reliably: five
playable BLUFOR slots and no engine-spawned Eden fixture tree. An audit-only nested `Entities`
configuration is included for the loadout scraper; the engine continues to spawn the proven
legacy playable group.

The repository mission folder is a template, not a release copy. Before every run,
`build_pr_review_audit.py` creates a disposable mission containing the exact roots listed in
`releaseVerificationAndDeployment/config.json`:

- `MissionScripts`
- `Pictures`
- `description.ext`
- `economyConfig.sqf`
- `init.sqf`
- `initPlayerLocal.sqf`
- `initServer.sqf`
- `LICENSE`
- `README.md`

The builder then adds the working audit `mission.sqm`, audit records, and three small hooks. The
real pack entry points remain intact and run first. This means the mission uses the same
`description.ext`, CfgFunctions registration, startup behaviour, ACE integration, modules and
optional-system defaults as the development build under review.

After production startup completes, the server creates the physical feature range through the
same public setup functions mission makers use. It includes Audit Control, Mission Flow, loadouts
and crates, a fully fitted MHQ, an isolated VVD lane, paradrop, all Economy areas, EW, two party
tables, forty interaction fixtures, a live EOD charge, Zeus, and registered-function stations.
These are real multiplayer objects, not registration-only assertions.

The east test range adds sixteen repeatable stations for the newer full systems:

- Persistence dependency gate, object registration and manual save
- ACE patient treatment feedback
- Hazardous-environment exposure and decay
- Tree felling and regrowth
- Emergency dismount from an overturned vehicle
- Accessibility PID against friendly AI
- Explosive wall breaching and reset
- Object scaling and transform helpers
- AI rebalance profiles and restoration
- Field resupply hub, carrier, deployment and salvage
- Tactical display with friendly and known-hostile contacts
- Dynamic AA creation and teardown
- Airborne gunship spawn, assignment, service and removal
- Vehicle recovery packaging, transport and workshop restoration
- Squad rally deployment, regroup, expiry and removal
- Nested-folder playable loadout scrape and limited arsenal

Every station has an information stand and ACE-first, vanilla-fallback test controls. Audit Control offers
teleports to each station. Dynamic AA and the gunship are created only when requested. Persistence
remains disabled unless its compatible server extension is detected. Reset actions allow repeated
testing without restarting the mission.

## Routine manual test

Close every Arma client and server, then run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  .\releaseVerificationAndDeployment\launch_pr_review_audit.ps1
```

The launcher always uses a hosted multiplayer session, 1920×1080, `-noBattlEye`, and the required
CBA, ACE, ZEN and ACRE2 mods. Select **Virtual Reality > WMP PR REVIEW AUDIT > Play**, choose a
slot, then press **OK**.

Manual mode is the default. It loads the whole pack but does not run state-mutating automated
cases. A server-owned Zeus curator is assigned to the first connected player so the WMP and
Economy modules can be tested. Use `-Mode Automated` only for a disposable focused smoke test.

For Zeus/script parity acceptance, do not stop after confirming that a module is listed. Place or
open every module and confirm its resulting world or server state. The focused regression set is:

- Jammer: create one inactive band-limited emitter with its per-emitter 3D marker off, then one
  with the marker on; confirm ordinary players never receive that overlay.
- Tracker: apply a custom label and an inactive initial state, then verify the public tracker
  registry and intended-side map rendering.
- Economy: open Ground Command, Presets, Purge, Completed Building and Delivery Point; confirm the
  modal owns mouse and keyboard input, closes without removing Zeus, and applies the same state
  represented by its exported script calls.
- Supply, medical, loadout and convoy adapters: confirm the server or AI-group owner performs the
  mutation and that a late-joining client sees the resulting object/action state.

Record these as in-engine results. A clean `zeus_script_parity_checker.py` run proves static
registration and call-path wiring, not runtime usability.

## Build without launching Arma

```powershell
python .\releaseVerificationAndDeployment\build_pr_review_audit.py `
  --destination .\.qa\staged\WMP_PR_Review_Audit.VR `
  --suite all --mode manual
```

`audit_build_manifest.json` records the release roots, WMP version, mission format, suite and
mode, and confirms that the nested playable-loadout fixture was included. Repository tests compare every staged `MissionScripts` and `Pictures` file byte-for-byte
with the worktree and fail if the audit stops using the release allowlist.

Product fixes are always made in the repository release sources. The installed Arma `MPMissions`
copy is disposable and never a source of truth. Range-only navigation and reset code remains under
`releaseVerificationAndDeployment` and is excluded from release archives.

The generated Eden `WMP_FPA.VR` mission and its launchers remain experimental and are not release
evidence. Its reusable range setup scripts are staged inside the working PR-review mission.
