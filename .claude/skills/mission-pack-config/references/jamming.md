# Radio jamming (ACRE2 + TFAR)

Localised, area-denial jamming. A *jammer* is any world object with a
radius; radios inside lose comms with linear falloff at the edge. Enabled by
default (`Waldo_Jamming_Enable = true`) but **has zero effect until a jammer
is placed** — safe to leave on in every mission.

## Architecture

Server-authoritative registry (`Waldo_Jamming_Registry`), client-local
engines. Placing/toggling/removing jammers always goes through the server
(calls forward automatically if made from a client). Each client installs
the radio engines from `init.sqf` (JIP-safe) — the ACRE2 custom signal
function and/or TFAR throttle loop, plus an on-screen jammed watcher.

## Config (`MissionConfig\electronicWarfareConfig.sqf`) — server, JIP-published

All entries live here now, not in `init.sqf`/`initServer.sqf` — edit the
config file, not a `setVariable` call pasted into an init file.

```sqf
["Waldo_Jamming_Enable", true, true],          // starts EW service; still no jammer until one is registered
["Waldo_Jamming_Notify", true, true],          // on-screen interference feedback
["Waldo_Jamming_LOS", true, true],             // terrain between jammer and radio blocks the field
["Waldo_Jamming_BurnThrough", true, true],     // higher-power radios resist jamming
["Waldo_Jamming_BurnThroughRef", 500, true],   // ADVANCED reference power (mW)
["Waldo_Jamming_Curve", "LINEAR", true],       // ADVANCED LINEAR or INVSQ falloff
["Waldo_Jamming_Destructible", true, true],    // destroying the jammer object auto-deregisters it
["Waldo_Jamming_GmOverlay", false, true],      // ADVANCED curator-only Draw3D diagnostics
["Waldo_Jamming_ScanRange", 3000, true],       // ADVANCED handheld RDF max scan range (m)
["Waldo_Jamming_ScanBearingArc", 30, true],    // NEW: total vague bearing sector width (deg) reported by a scan
["Waldo_Jamming_ScanDistanceBands", [35, 150, 600], true], // NEW: metre thresholds for nearby/close/distant RDF wording
["Waldo_Jamming_AllowPlayerToggle", true, true],   // NEW: legacy direct activate/deactivate action
["Waldo_Jamming_DisableChallenge", true, true],    // NEW: true = active jammers require the disable interaction procedure instead of a plain toggle
["Waldo_Jamming_DisableChallengeId", "circuit", true], // NEW: registered interaction-equipment ID used for the disable procedure
["Waldo_Jamming_DisableDifficulty", "standard", true], // NEW: easy | standard | hard | expert
["Waldo_Jamming_DisableEngineerOnly", false, true],    // NEW: true restricts the disable attempt to ACE engineers
["Waldo_Jamming_DisableResult", "DISABLE", true]       // NEW: DISABLE (repairable/reactivatable) or DEACTIVATE (ordinary off)
```

## Placing a jammer

```sqf
// Object init field, simple form:
[this] call Waldo_fnc_Jammer;                         // 300m, jams everyone, all bands
[this, 500, "EAST"] call Waldo_fnc_Jammer;             // 500m, OPFOR only
// Full params, from a trigger/script:
[myTower, 800, "ALL", [[30, 88]], 50, 1, true, true, [90, 60], [4, 2], true] call Waldo_fnc_Jammer;
// params: [object, radius, affectedSides, bands, falloff, strength, active, createMarker, sector, duty, jamUAV]
```

Returns a numeric jammer id.

- `affectedSides`: `"ALL"`, a side, or an array; accepts side values or
  strings (`"WEST"/"BLUFOR"`, `"EAST"/"OPFOR"`, `"IND"/"INDFOR"`,
  `"CIV"/"CIVILIAN"`).
- `bands`: `"ALL"` or array of `[minMHz, maxMHz]` ranges — **ACRE2 only**,
  TFAR jamming is always broadband regardless of this param.
- `sector`: `[]` for omni, `[bearing, arc]` for a directional cone.
- `duty`: `[]` constant, or `[onSec, offSec]` to pulse.
- `jamUAV`: also jams drones in the field (see UAV section below).

## Managing jammers (server-authoritative, safe from a client)

```sqf
[myTower, false] call Waldo_fnc_JammerToggle;   // switch off (omit bool to flip)
[myTower, true]  call Waldo_fnc_JammerRemove;   // remove + delete the object
```

`Waldo_fnc_JammerToggle` respects `Waldo_Jamming_AllowPlayerToggle` /
`Waldo_Jamming_DisableChallenge` for player-triggered calls the same way the
in-game action does — a script/trigger call from a trusted mission source
bypasses those player-facing gates.

## Player-facing actions and the disable challenge (new)

Every jammer object gets ACE actions **Toggle Radio Jammer** and **Disable
Radio Jammer**. With `Waldo_Jamming_DisableChallenge` at its default `true`,
disabling an *active* jammer now requires completing the configured
interaction-equipment procedure (`Waldo_Jamming_DisableChallengeId`, default
`"circuit"`, at `Waldo_Jamming_DisableDifficulty`) rather than an instant
toggle — see `references/misc-mission-maker-tools.md` or the interaction
minigames reference for how those procedures play out. `Waldo_Jamming_DisableEngineerOnly`
restricts the attempt to ACE engineers when `true` (default `false`, anyone
may try). On success the jammer moves to `Waldo_Jamming_DisableResult`:
`"DISABLE"` (repairable — someone can toggle it back on later) or
`"DEACTIVATE"` (ordinary off state, same as the old plain toggle). Every
player also gets an ACE self-action **Scan for Radio Jammers**
(`Waldo_fnc_JammerScan`) reporting bearing (quantised to `ScanBearingArc`
sectors) / coarse range (`ScanDistanceBands` wording) / strength to the
nearest active emitter.

## Global model flags (reference, all in `electronicWarfareConfig.sqf`)

| Flag | Default | Effect |
|---|---|---|
| `Waldo_Jamming_LOS` | `true` | Terrain between jammer and radio blocks the field |
| `Waldo_Jamming_BurnThrough` | `true` | Higher-power radios resist jamming (effective radius shrinks by `(power/ref)^0.35`) |
| `Waldo_Jamming_BurnThroughRef` | `500` | Reference radio power (mW) |
| `Waldo_Jamming_Curve` | `"LINEAR"` | Falloff shape: `"LINEAR"` or `"INVSQ"` |
| `Waldo_Jamming_Destructible` | `true` | Destroying the jammer object auto-deregisters it |
| `Waldo_Jamming_GmOverlay` | `false` | Curator-only Draw3D marker/facing-line over each jammer |
| `Waldo_Jamming_ScanRange` | `3000` | Detection range (m) of the handheld RDF ACE self-action |

## UAV / UGV jamming (`jamUAV = true`)

Drones in the field are jammed too: the server freezes autonomous drone AI
(`Waldo_fnc_JammingUavServer`); a controlling player's client
(`Waldo_fnc_JammingUavClient`) degrades the video feed as the link weakens
and severs the terminal link at near-total jamming, showing a persistent
`UAV LINK DEGRADED` panel (IDC 5311) then a separate datalink-loss notice. A
UAV with an actively connected player remains an engine edge case with no
guaranteed teardown — mention this caveat if a user is relying on it.

## Model requirement

ACRE2 jamming only works under signal model **LOS Multipath** (default) or
**Arcade** — never under *LOS Simple* (see `acre2.md`).

## Zeus ("Waldos Mission Modules")

**Radio Jammer - Place** (`Waldo_fnc_ZenJammerPlace`; full dialog matching
the script params above, plus per-emitter curator 3D marker and emitter
class), **Radio Jammer - Toggle Nearest** (`Waldo_fnc_ZenJammerToggle`),
**Radio Jammer - Remove Nearest** (`Waldo_fnc_ZenJammerRemove`).
