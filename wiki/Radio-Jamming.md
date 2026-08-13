# Radio Jamming

> **Use this page when:** you need ACRE2 or TFAR interference fields, player feedback, UAV effects, or Zeus controls.

_Associated Files: `init.sqf`, `MissionScripts\MissionInit\Jamming\jammingInit.sqf`, `jammerCreate.sqf`, `jammerToggle.sqf`, `jammerRemove.sqf`, `jammerInteraction.sqf`, `jammerDisableServer.sqf`, `jammingFactor.sqf`, `jammingAcreSignal.sqf`, `jammingTfarLoop.sqf`, `jammerScan.sqf`, `jammerMapDraw.sqf`, `jammingHud.sqf`, `MissionScripts\ZenModules\Zen_jammerPlaceModule.sqf`, `Zen_jammerToggleModule.sqf`, `Zen_jammerRemoveModule.sqf`, `Waldo_fnc_Jammer`, `Waldo_fnc_JammerToggle`, `Waldo_fnc_JammerRemove`_

## Radio Jamming (ACRE2 / TFAR)

Localised radio jamming lets you deny communications in an area. A **jammer** is any object configured with a radius. Radios inside its field lose signal, then recover through a soft edge as they leave. The system supports **both ACRE2 and TFAR**.

Use it for EW objectives ("destroy the jammer to restore comms"), no-comms insertions, roleplay around a signals site, or just to make an area go dark on cue.

## What it does

* **ACRE2:** inside a jammer field, the signal between radios is pushed toward the noise floor. Transmissions degrade, then drop out. A jammer can target specific frequency **bands**, such as VHF only.
* **TFAR:** inside a jammer field, receive and transmit ranges fall toward zero. Full-strength jamming disables the radio. TFAR jamming is **broadband**.
* **Both:** jamming is strongest inside the **radius**, then falls to zero across the **falloff** distance. A field can target chosen sides, operate inside a cone, or pulse.

The feature is **on by default** but does nothing until you actually place a jammer, so leaving it enabled costs you nothing.

> **ACRE2 requirement:** your ACRE2 **signal model** must be **LOS Multipath** (the default) or **Arcade**. ACRE2 does not expose the hook this uses under *LOS Simple*, so jamming will silently do nothing on that model.

## Player feedback

The interface identifies radio interference as soon as the player enters an active field:

* A persistent **ELECTRONIC WARFARE** panel shows `RADIO INTERFERENCE`, signal loss as a percentage and bar, and `LINK QUALITY DEGRADED`.
* An entry notice states that signal strength is degraded and tells the player to leave the field or disable the emitter.
* A **COMMS RESTORED** notice appears after leaving the field.
* The **Scan for Radio Jammers** ACE self-action reports bearing, coarse range, and signal strength.

Set `Waldo_Jamming_Notify` to `false` to disable the on-screen panel and notices.

## The quickest setup (Eden init field)

Place any object (an antenna, a vehicle, a generator), then in its **init field**:

```sqf
[this] call Waldo_fnc_Jammer;
```

That's a 300 m jammer that jams everyone on every band. Done.

Want more control? The full form is:

```sqf
[this, 500, "EAST"] call Waldo_fnc_Jammer;                                    // 500 m, jams OPFOR only
[this, 800, "ALL", [[30, 88]], 50, 1, true, true] call Waldo_fnc_Jammer;      // VHF-only, with a map marker
[this, 800, "ALL", "ALL", 50, 1, true, true, [90, 60]] call Waldo_fnc_Jammer; // a 60-deg cone facing 090
[this, 600, "ALL", "ALL", 50, 1, true, false, [], [4, 2]] call Waldo_fnc_Jammer; // pulses 4s on / 2s off
[this, 600, "ALL", "ALL", 50, 1, true, false, [], [], false, true] call Waldo_fnc_Jammer; // curator 3D marker for this emitter only

// Require the shared circuit-bypass interaction before players can disable this jammer:
private _interaction = createHashMapFromArray [
    ["disableChallenge", true],
    ["challengeId", "circuit"],
    ["difficulty", "standard"],
    ["engineerOnly", true],
    ["resultMode", "DISABLE"],
    ["allowPlayerToggle", true]
];
[this, 600, "WEST", "ALL", 50, 1, true, false, [], [], false, false, _interaction]
    call Waldo_fnc_Jammer;
```

## `Waldo_fnc_Jammer` parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | object | Object | Required | The emitter object. Its position is the centre of the field. |
| 1 | radius | Number | `300` | Full-strength jamming radius, in metres. |
| 2 | affectedSides | String / Array | `"ALL"` | `"ALL"`, a side, or an array. Accepts `"WEST"`/`"BLUFOR"`, `"EAST"`/`"OPFOR"`, `"IND"`/`"INDFOR"`, `"CIV"`/`"CIVILIAN"`, or actual sides. Only listed sides are jammed. |
| 3 | bands | String / Array | `"ALL"` | `"ALL"`, or an array of `[minMHz, maxMHz]` ranges. **ACRE2 only.** TFAR ignores this value. |
| 4 | falloff | Number | `50` | Extra metres of linear falloff beyond the radius. `0` = a hard edge. |
| 5 | strength | Number | `1` | Jamming strength at full effect, `0`–`1` (`1` = total blackout). |
| 6 | active | Bool | `true` | Start switched on. |
| 7 | createMarker | Bool | `false` | Place a red "Radio Jammer" map marker on it. |
| 8 | sector | Array | `[]` | `[]` = omnidirectional, or `[bearing, arc]` for a directional cone facing `bearing` degrees, `arc` degrees wide. |
| 9 | duty | Array | `[]` | `[]` = constant, or `[onSec, offSec]` to pulse the jammer on and off. |
| 10 | jamUAV | Bool | `false` | Also jam UAVs/drones in the field (see below). |
| 11 | curator3DMarker | Bool | `false` | Show this emitter in the curator-only 3D overlay. Ordinary players never see it. |
| 12 | interactionOptions | Array / HashMap | `[]` | Optional field-action settings: `disableChallenge`, `challengeId`, `difficulty`, `engineerOnly`, `resultMode`, and legacy-named `allowPlayerToggle` (reactivation only). |

`Waldo_fnc_Jammer` returns a numeric **jammer id** you can keep to toggle or remove it later. Calling it again on the same object updates that jammer in place (it never stacks).

## UAV / drone jamming (counter-UAS)

Set the **jamUAV** flag (param 10, or the "Also Jam UAVs / Drones" checkbox in the Zeus module) and the field becomes counter-drone as well as anti-radio:

* **Autonomous drones** inside the field stop moving and searching while their AI is suppressed.
* **Player-controlled drones** get a **degrading video feed** as the operator flies into the field, and at near-total jamming the **datalink is cut** and the terminal disconnects.

```sqf
// A 400 m counter-UAS bubble that jams radios AND drones for everyone:
[this, 400, "ALL", "ALL", 50, 1, true, true, [], [], true] call Waldo_fnc_Jammer;
```

The operator sees a persistent **UAV LINK DEGRADED** panel with signal-loss guidance. Near-total jamming shows a separate datalink-loss notice and disconnects the terminal. The same Toggle/Disable ACE actions, Zeus controls, and RDF scan apply to UAV-enabled jammers.

## The jamming model (global toggles in `init.sqf`)

These let you tune how realistic/gamey the jamming feels. All are on by default.

| Flag | Default | Effect |
|---|---|---|
| `Waldo_Jamming_LOS` | `true` | **Terrain line-of-sight.** A hill or ridge between the jammer and a radio blocks the field. High ground extends practical coverage. |
| `Waldo_Jamming_BurnThrough` | `true` | **Power burn-through.** Higher-power radios, such as a PRC-117F, resist jamming and reduce the effective radius. |
| `Waldo_Jamming_BurnThroughRef` | `500` | Reference radio power in mW. A radio at this power receives full effect; more powerful radios burn through. |
| `Waldo_Jamming_Curve` | `"LINEAR"` | Falloff shape at the edge: `"LINEAR"` or `"INVSQ"` for a sharper inverse-square response near the centre. |
| `Waldo_Jamming_Destructible` | `true` | Destroying the emitter automatically removes its jammer entry and restores affected links. |
| `Waldo_Jamming_GmOverlay` | `false` | Opt-in curator-only floating marker (and facing line for cones) over every jammer. Ordinary players never see it. |
| `Waldo_Jamming_ScanRange` | `3000` | Hard cap (m) on the handheld RDF scan; a source is reported only while the operator is also inside its currently active field. |
| `Waldo_Jamming_ScanBearingArc` | `30` | Width in degrees of the quantised bearing sector reported to the operator. |
| `Waldo_Jamming_ScanDistanceBands` | `[35, 150, 600]` | Absolute metre thresholds separating deliberately vague `VERY CLOSE`, `NEARBY`, `DISTANT` and `VERY DISTANT` reports. Absolute bands prevent a nearby source being described as distant merely because it has a large configured footprint. |
| `Waldo_Jamming_AllowPlayerToggle` | `true` | Legacy setting name retained for compatibility. It now allows **Activate Jammer** while an emitter is inactive. Players must use **Disable Jammer** to turn an active field off, so the direct/challenged procedure cannot be bypassed. Activation also resets the optional procedure for repeat use. |
| `Waldo_Jamming_DisableChallenge` | `true` | Require the shared field-equipment procedure before player disablement. Set `false` only when an immediate **Disable Jammer** action is preferred. The ordinary operator toggle cannot bypass disablement while the jammer is active. |
| `Waldo_Jamming_DisableChallengeId` | `"circuit"` | Shared procedure used by challenge-enabled emitters. Any registered interaction challenge id is accepted. |
| `Waldo_Jamming_DisableDifficulty` | `"standard"` | `easy`, `standard`, `hard`, or `expert`. |
| `Waldo_Jamming_DisableEngineerOnly` | `false` | `false` lets any player attempt the procedure; `true` requires ACE engineer capability. The server validates this again when the attempt completes. |
| `Waldo_Jamming_DisableResult` | `"DISABLE"` | `DISABLE` leaves a curator-reactivatable object; `DESTROY` destroys and deregisters it. |

## EW toolkit (for players, no Zeus needed)

Every jammer and every player gets ACE actions so an EW team can play the cat-and-mouse in the field:

| Action | Where | Who | What it does |
|---|---|---|---|
| **Activate Jammer** | on an inactive, reactivatable jammer object | anyone | Restores an inactive or successfully disabled emitter. Activation clears its field-disabled flag and resets the optional procedure so it can be completed again. A destroyed emitter cannot be restored. |
| **Disable Jammer** | on a challenge-enabled jammer object | everyone by default for a Zeus-created objective; optionally engineers only | Runs the selected shared interaction procedure. The server revalidates actor, distance, optional engineer status, registry state and completion before disabling or destroying the emitter. |
| **Disable Jammer** | on a non-challenge jammer object | everyone by default for a Zeus-created objective; optionally engineers only | Immediately applies the configured result: disable the field while retaining the prop, or destroy and deregister the emitter. |
| **Scan for Radio Jammers** | self-interaction (ACE) | anyone | Reports a broad **bearing sector** and deliberately vague **distance band** for the nearest source currently affecting the operator. The scan respects the affected side, active radius plus falloff, directional sector, pulse phase, terrain occlusion and the `Waldo_Jamming_ScanRange` hard cap. It does not expose an exact bearing, numerical distance or aggregate signal-strength value. |

## Turning jammers on/off and removing them from script

Both accept the jammer **object** or its **id**. The server owns the result, so calls from triggers, clients, and scripts are forwarded safely.

Activation uses the same server-authoritative call as the Zeus/script control. It clears a prior field-disabled state and resets the optional procedure. Players never receive a separate Deactivate action: use **Disable Jammer** for the intended gameplay path, or the Zeus/script toggle for administration.

```sqf
[myTower, false] call Waldo_fnc_JammerToggle;   // switch off (omit the bool to just flip it)
[myTower]        call Waldo_fnc_JammerRemove;    // remove the jammer, keep the object
[myTower, true]  call Waldo_fnc_JammerRemove;    // remove the jammer AND delete the object
```

A destructible jammer can drive an EW objective without a separate trigger:

```sqf
// In the jammer tower's init - blow it up in-game and comms come back on their own:
[this, 600, "WEST"] call Waldo_fnc_Jammer;
```

## Zeus usage

Three modules live under **Modules > WMP Electronic Warfare** (Zeus Enhanced required):

| Module | Action |
|---|---|
| **Jammer - Place Emitter** | Opens a dialog for radio behaviour, emitter type, and an optional field-disable procedure. Zeus exposes only enable, procedure and difficulty. Engineer-only, disable-not-destroy and bypass prevention are semantic defaults; advanced overrides remain available through the script API. |
| **Jammer - Toggle Nearest** | Switches the nearest registered jammer on or off. |
| **Jammer - Delete Nearest** | Removes the nearest registered jammer and deletes its emitter object. |

When the module is placed on empty ground, the selected displayed emitter class is sent directly to the server and that exact object is spawned, simulation-enabled, added to every curator, and transferred to the requesting curator for smooth movement. Place the module directly on any existing object to expose **Use object under module** instead: that object becomes the emitter without changing its class, transform, damage, cargo, or simulation state. This supports mission and mod objects without asking Zeus for a raw classname. In both modes the field and interactions remain attached to the live object after it is moved. The dialog also selects whether field disablement is public or engineer-only and whether success disables the field or destroys the prop. Enable **Show Curator 3D Marker** for only that emitter. `Waldo_Jamming_GmOverlay = true` remains the global mission-maker override that displays every registered jammer.

## Global options (`init.sqf`)

```sqf
Waldo_Jamming_Enable = true;                                        // false = feature off entirely
missionNamespace setVariable ["Waldo_Jamming_Notify", true, true];  // on-screen jamming HUD + timed hints
// plus the model toggles in the table above
```

## How it works (for the curious)

The server owns and broadcasts the jammer list, so late-joining players receive every current emitter. Each player runs the engine for the loaded radio mod through an ACRE2 custom signal function, a TFAR loop, or both. `Waldo_fnc_JammingFactor` applies duty cycle, sides, band, cone, terrain LOS, burn-through, and falloff. A link degrades when either endpoint is inside a matching active field.

## See also

* [ACRE 2 Long Range Radio](ACRE-2-Long-Range-Radio-Presetting): radio channel setup
* [Mission Diagnostics](Mission-Diagnostics): warns if jamming is enabled with no radio mod loaded
* [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
* [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
