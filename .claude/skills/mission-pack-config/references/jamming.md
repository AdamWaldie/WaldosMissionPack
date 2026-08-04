# Radio jamming (ACRE2 + TFAR)

Localised, area-denial jamming. A *jammer* is any world object with a
radius; radios inside lose comms with linear falloff at the edge. Enabled by
default (`Waldo_Jamming_Enable = true` in `init.sqf`) but **has zero effect
until a jammer is placed** — safe to leave on in every mission.

## Architecture

Server-authoritative registry (`Waldo_Jamming_Registry`), client-local
engines. Placing/toggling/removing jammers always goes through the server
(calls forward automatically if made from a client). Each client installs
the radio engines from `init.sqf` (JIP-safe) — the ACRE2 custom signal
function and/or TFAR throttle loop, plus an on-screen jammed watcher.

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

## Global model flags (`init.sqf`)

| Flag | Default | Effect |
|---|---|---|
| `Waldo_Jamming_LOS` | `true` | Terrain between jammer and radio blocks the field |
| `Waldo_Jamming_BurnThrough` | `true` | Higher-power radios resist jamming (effective radius shrinks by `(power/ref)^0.35`) |
| `Waldo_Jamming_BurnThroughRef` | `500` | Reference radio power (mW) |
| `Waldo_Jamming_Curve` | `"LINEAR"` | Falloff shape: `"LINEAR"` or `"INVSQ"` |
| `Waldo_Jamming_Destructible` | `true` | Destroying the jammer object auto-deregisters it |
| `Waldo_Jamming_GmOverlay` | `false` | Curator-only Draw3D marker/facing-line over each jammer |
| `Waldo_Jamming_ScanRange` | `3000` | Detection range (m) of the handheld RDF ACE self-action |

```sqf
Waldo_Jamming_Enable = true;                                          // false = feature off entirely
missionNamespace setVariable ["Waldo_Jamming_Notify", true, true];    // on-screen "radio jammed" prompt
```

## Player-facing actions

Every jammer object gets ACE actions **Toggle Radio Jammer** (anyone) and
**Disable Radio Jammer** (engineers, destroys it). Every player gets an ACE
self-action **Scan for Radio Jammers** (`Waldo_fnc_JammerScan`) reporting
bearing / coarse range / strength to the nearest active emitter.

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

**Jammer: Place New Emitter** (full dialog matching the script params above,
plus per-emitter curator 3D marker and emitter class), **Jammer: Toggle
Nearest Emitter**, **Jammer: Delete Nearest Emitter**.
