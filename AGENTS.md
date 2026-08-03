# WMP agent guidance

## Non-negotiable source conventions

- Every SQF file must start with a useful documentation block: `Author: WaldoTheWarfighter`,
  purpose, locality/authority and repeat/JIP behaviour, arguments with types/defaults, return value,
  current callers, and a real example. Improve nearby incomplete headers when changing a file.
- Never use Claude, ChatGPT, Codex, an imported script author, or an upstream project as the author.
- Preserve the intentional ACE treatment spelling of `succeed`; do not "correct" it.
- Put features in their semantic subsystem. Do not recreate a generic `FeatureSystems` dumping ground.

## Locality, authority and JIP

- `initServer.sqf` owns one-time authoritative setup and initial public state. `initPlayerLocal.sqf`
  owns interface, local actions, local event handlers and per-player setup. Multiplayer `init.sqf`
  runs on every machine and is not a safe home for unguarded authoritative defaults.
- Never assume event-script ordering across different machines. Modules run before event scripts;
  JIP public state can arrive before multiplayer `init.sqf`. Guard defaults with `isNil` so a joining
  machine cannot overwrite live server state.
- For runtime-editable settings, the server changes and broadcasts the authoritative value. Send an
  ordered settings/snapshot payload before activating dependent client behaviour, expose a readiness
  sentinel, and provide an explicit state request/replay path for JIP.
- Server ownership of state does not imply server ownership of every operation. Check the locality of
  the affected unit, vehicle, group, UI or command and deliberately remote the operation to its owner.
  Re-run local setup when locality changes where the feature supports headless clients.
- Make setup, event-handler installation and cleanup repeat-safe. Track action/EH/PFH identifiers;
  remove obsolete versions before reinstalling. A public variable alone does not replay side effects.

## SQF scope and settings transport

- `params` creates private variables in its current scope. Do not declare defaults outside an
  `if`/`switch` block, run `_settings params [...]` inside that block using the same names, and then
  expect the outer values to have changed. This silently preserved every default in the jammer ZEN
  server handler. Parse into the consuming scope or assign each outer variable explicitly.
- Prefer named key/value payloads for evolving ZEN-to-server APIs. Parse them server-side with a
  HashMap and `getOrDefault`; retain explicit positional adapters only for documented legacy calls.
  Tests must assert that every dialog key is both sent and read.
- Do not couple independent selections. Side/ownership and asset class are separate concerns; object
  class, faction pool and operational side must remain independently selectable where valid.
- Validate enum values, config classes, ranges and object existence again on the authoritative
  machine. Client dialog validation is usability, not security or state authority.

## ZEN placement and movable world objects

- A module that requires a target must reject `objNull` with a clear notification. Do not silently
  guess the nearest object; the tracker module is the reference behaviour.
- A placement module with an object selector must send the selected classname itself, and the server
  must log/instantiate that exact class. Keep UI label arrays and value arrays aligned.
- For an existing object, preserve its intentional simulation state. For a spawned functional object,
  place it safely before enabling simulation. Do not stack live vehicles or aircraft at `[0,0,0]` or
  on a common line.
- Zeus-movable objects need suitable locality/ownership. Transfer newly spawned props to the requesting
  curator when appropriate, avoid server loops that continuously overwrite curator transforms, and
  keep interactions attached to the object rather than its original coordinates.
- All ZEN dialogs must use labelled selectors/dropdowns and contextual help. Raw config classname or
  object-id entry is not an acceptable primary operator workflow. Keep module categories grouped and
  avoid adding a module when an ordinary self/object interaction is the better control surface.

## ACE interactions and state machines

- Install ACE actions locally for every interface client, including JIP, after ACE is available.
  Authoritative effects still execute on the server or object owner. Use vanilla `addAction` only for
  features whose design explicitly requires it or as the documented non-ACE fallback.
- Action labels and visibility must describe current authoritative state. Prefer separate semantic
  actions over an opaque Toggle action, but never expose a convenience action that bypasses a gated
  procedure.
- For jammers, **Disable Jammer** is the only player-facing path that turns an active field off.
  Optional **Activate Jammer** appears while the field is inactive, including after a successful
  `DISABLE`; activation clears `Waldo_Jamming_FieldDisabled` and resets the optional challenge for
  repeat use. `DESTROY` remains terminal. Never expose player Deactivate alongside or instead of the
  intended disable procedure; Zeus/script toggle remains the administrative control.
- When an object moves or changes locality, confirm its action version is still present. Version local
  installations and remove the old action paths before adding replacements.
- Do not add empty category actions. If one direct action is the whole workflow, show that action at
  the meaningful level and launch the optional shared challenge from it.

## Notifications and shared UI

- Do not use `hint` for feature feedback. Route ordinary messages through the WMP notification flow,
  with coalescing/queue limits and the global lane/overflow reservation hooks.
- Specialist displays must reserve/release their screen region through the same global hooks. Do not
  hard-code feature-pair exceptions. ACE interaction UI has priority while open.
- Treatment feedback belongs in the padded bottom-centre region and must end with the real ACE action,
  not an unrelated long timer. Do not show loadout-save feedback during the fake loading screen.
- UI themes and colour-vision profiles are presentation only: all WMP HUD/plugin elements should use
  the shared theme/profile accessors without changing mechanics.

## Full-pack audit mission and launch

- Use `releaseVerificationAndDeployment/launch_pr_review_audit.ps1` for the ongoing full-pack audit.
  It builds a fresh disposable mission, launches a dedicated server and client, uses `-noBattlEye`,
  and defaults to `3840x2160`. Do not substitute an editor-only launch or an old cached mission.
- Wait for the server readiness marker, then verify the client reaches the correct mission lobby.
  Select the playable test slot and press OK; arriving at the main menu, editor, or lobby alone is not
  a successful mission launch. Confirm the RPT reports the VR mission and pack initialization.
- The audit mission must set up the dependencies each station needs: Zeus access, respawn base and
  selectable respawn, economy presets, simulation-enabled live vehicles/crews, safe spacing, correct
  target object types, and actions that exercise the real feature path.
- Rebuild the disposable mission after source changes. A running audit instance contains the files
  staged when it launched, not later working-tree edits.

## Static and in-engine acceptance

- Run the SQF validator, repository unit tests, wiki checks and Zeus/script parity checker. Treat them
  as regression gates, not proof that an Arma interaction works.
- On Windows, do not run the full unit suite/audit builder concurrently with scanners that read the
  generated `WMP_FPA.VR` tree. The builder refreshes that tree in place and a mapped reader can cause
  WinError 1224 plus a false source-parity failure. Run the builder/tests first, then scanners.
- For ZEN changes, test the dialog selection, client payload, server log, created world object/state,
  curator movement, ACE action, authoritative mutation, cleanup and JIP replay. Compare requested and
  resulting class/settings in the RPT.
- For vehicle/aircraft mechanics, test simulation, locality migration, waypoint movement/deletion,
  object deletion and recreation, safe placement and repeated use. Static objects are not substitutes
  for vehicles where the engine command requires simulation or AI locality.
- Keep the PR body and wiki exhaustive as behaviour changes; list actual features, controls, defaults,
  locality/JIP design, dependencies, script examples, limitations and in-engine retest status.

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
