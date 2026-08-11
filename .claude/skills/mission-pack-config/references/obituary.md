# Obituary / confirmed-death reporting

A medic-only "Pronounce Dead" ACE interaction on a corpse that replaces terse
default death messages with a formatted KIA report: time of death, cause,
grid-reference location, and a friendly-fire callout when applicable. Feeds a
"Confirmed deaths" section into the ENDEX After-Action Report (see
`endex-aar.md`), listing each victim's name and how many times their death
was confirmed.

## Config (`MissionConfig\interfaceConfig.sqf` — player local)

```sqf
["Waldo_Obituary_Enable", true],              // installs the interaction; defaults ON, unlike other MedicalSystems features
["Waldo_Obituary_ChatAnnounce", true],        // also broadcasts the terse systemChat pronounce line
["Waldo_Obituary_DiaryPollInterval", 3]       // seconds between local diary-record sync checks
```

## Start

```sqf
[] call Waldo_fnc_ObituaryInit;
```

Runs automatically from `initPlayerLocal.sqf` when `Waldo_Obituary_Enable` is
true (the default). No ZEN module — this is an always-available medic action,
not a curator-authored placement.

## Gotchas

- The interaction is on **`ACE_MainActions`** (a target/corpse interaction),
  **not `ACE_SelfActions`**. It shows up when interacting with the body, not
  in your own self-interaction menu — this is intentional, not a bug to fix.
- Every name-dependent value (victim name, instigator name) and the full
  cause-of-death classification are computed and cached **at the moment of
  death**, not when the medic later performs the pronounce action. This
  guards against the victim (or the killer/instigator) having disconnected
  by the time someone gets around to pronouncing them — the report always
  shows the correct cached name, never a stale/blank live lookup.
- Friendly fire is still flagged normally, **except** when the instigator is
  a Zeus curator remote-controlling a unit — `getAssignedCuratorLogic` is
  the mechanism used to detect that, since a curator-possessed unit also
  makes `isPlayer` true (indistinguishable from a real human by that check
  alone).
- Every player gets **one** "Obituary" diary record that updates in place as
  deaths are confirmed — not one record per death. It also survives the
  reading player's own respawn (Arma replaces the player object on
  respawn), using the same remove-then-recreate pattern as the ACRE2
  CEOI/Babel diary records.
- `Waldo_AAR_Obituary` (the AAR tally this feeds) is populated only when a
  death is actually **pronounced**, not at the moment of death — it is a
  distinct, later, player-triggered count from the AAR's own KIA/friendly-fire
  tallies in `endex-aar.md`.
