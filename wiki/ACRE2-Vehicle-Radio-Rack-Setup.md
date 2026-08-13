# ACRE2 Vehicle Radio Rack Setup

> **Use this page when:** a vehicle, drone, command post or radio table needs a known vehicle-radio
> starting state. Player-carried radios use the separate ACRE communications configuration.

WMP supports all four useful rack operations:

- initialise racks already supplied by the vehicle;
- apply an existing ACRE radio preset before initialisation;
- add a physical rack and optionally start it with a compatible radio;
- tune, empty, replace or remove a removable rack after initialisation.

This follows ACRE2's public [Vehicle Racks framework](https://acre2.idi-systems.com/wiki/frameworks/vehicle-racks).

## Before you begin

1. Enable the main ACRE communications setup in `MissionConfig\acreConfig.sqf`.
2. Define and test the named nets used by player-carried radios first.
3. Keep rack profiles below those net definitions in the same file. A rack assignment may refer to a
   net key such as `COY`, but it does not create that net.
4. Place a vehicle/object and call one rack profile from its Eden Init field.
5. Test with a real ACRE-enabled player. Dedicated servers do not own an ACRE player interface, so
   WMP coordinates the authoritative request with an eligible connected ACRE client and verifies the
   returned rack state.

If you are new to the feature, place **ACRE2 Vehicle Radio Rack Example (Minimal)** before writing a
custom profile. It demonstrates the complete lifecycle with the least editable data.

## Recommended: central profile plus one short vehicle call

Edit `MissionConfig\acreConfig.sqf` and find `rackProfiles`. WMP ships three ready-to-use profiles
plus commented, copyable examples for every supported selector, hardware action, rack/radio pair and
access pattern. The commented examples are deliberately inert: enabling ACRE does not add, empty or
remove a rack until an object calls a profile containing that row.
Then paste this in the vehicle or object's Eden **Init** field:

```sqf
[this, "COMMAND_VEHICLE"] call Waldo_fnc_ACRE2RackSetup;
```

No `isServer` wrapper is required. The function forwards to the server itself.

A profile sitting in `acreConfig.sqf` does nothing until an object calls it. Several vehicles may
reuse the same profile.

## Reusing the same named radio nets

Rack profiles use the same net definitions as player-carried radios. If WEST already defines
`AIRGND` as PRC long-range channel 6, a vehicle assignment can request `"AIRGND"` instead of
repeating channel 6. The optional `netSide` setting chooses `WEST`, `EAST`, `GUER` or `CIV`.

`AUTO` first uses the vehicle class side, but neutral props do not express operational ownership;
give those profiles an explicit side. WMP also checks the radio family. A `PRC_LR` net can configure
a PRC-148, PRC-152 or PRC-117F rack radio, but cannot silently become a BF-888 or SEM52 channel.
Changing a net once therefore updates carried-radio and rack starting states together.

## Simplest inline call

To leave the hardware alone and set compatible already-mounted radios to WEST's named `COY` net:

```sqf
[this, [["netSide", "WEST"], ["assignments", [["ALL", "COY"]]]]] call Waldo_fnc_ACRE2RackSetup;
```

Empty racks reached through `"ALL"` are skipped. Explicitly selecting an empty rack reports a
problem unless the row also supplies a compatible radio to mount.

## Mix a central profile with a local exception

```sqf
[
    this,
    "COMMAND_VEHICLE",
    [["assignments", [[["ACRE_VRC110", 1], "AIRGND", "ACRE_PRC152"]]]]
] call Waldo_fnc_ACRE2RackSetup;
```

This loads `COMMAND_VEHICLE`, then replaces that profile's complete `assignments` setting for this
one vehicle. WMP does not perform a hidden array merge.

## Understanding central rack profiles

Each profile is:

```sqf
["PROFILE_NAME", [
    ["preset", "default3"],
    ["netSide", "WEST"],
    ["addRacks", []],
    ["assignments", []]
]]
```

| Setting | What it means |
|---|---|
| `preset` | Optional existing ACRE preset name applied before rack initialisation. `""` reuses the preset configured for `netSide`. |
| `netSide` | Side whose named net table is used: `WEST`, `EAST`, `GUER`, `CIV`, or carefully chosen `AUTO`. |
| `addRacks` | Physical racks WMP should ensure exist on the object. |
| `assignments` | Named-net/channel changes or radio/rack changes after ACRE has synchronized the rack IDs. |

The preset is not a WMP net name. It must already exist in ACRE's radio preset configuration. When
this is `""`, WMP deterministically reuses the selected side's preset rather than depending on which
player ACRE happens to select. Enter a different preset explicitly only when the rack needs a
different complete programme. This is the correct route for PRC-77/SEM70 frequency programming
because those radios are not ordinary numbered-channel radios.

## Adding a rack and its radio

```sqf
[this, [["addRacks", [
    ["ACRE_VRC110", [
        ["count", 1],
        ["displayName", "Command Radio"],
        ["shortName", "CMD"],
        ["removable", true],
        ["access", ["inside"]],
        ["disabled", []],
        ["mountedRadio", "ACRE_PRC152"],
        ["components", []],
        ["intercoms", []]
    ]]
]], ["assignments", [
    [["ACRE_VRC110", 1], "AIRGND", "ACRE_PRC152"]
]]]] call Waldo_fnc_ACRE2RackSetup;
```

`count` means the desired total number of that rack class on this object—not “add this many every
time.” If the call is retried after adding the first rack, WMP sees that it already exists and does
not duplicate it.

| Rack option | Beginner meaning |
|---|---|
| `displayName` | Name shown in the ACRE/ACE interaction menu. |
| `shortName` | Short GUI label; ACRE allows 1-4 characters. |
| `removable` | Whether the mounted radio can later be removed/replaced. |
| `access` | Who can access it. `['inside']` is the normal vehicle default; `['external']` suits a radio table. |
| `disabled` | Vehicle positions denied access. `[]` denies none. |
| `mountedRadio` | Compatible base radio, or `""` for an empty rack. |
| `components` | Advanced extra ACRE component classes. Beginners should use `[]`. |
| `intercoms` | ACRE intercom IDs connected to the rack, or `[]`. |

## Rack and radio compatibility

ACRE checks the physical connectors. WMP validates the five built-in pairs before requesting a
mount, so an incompatible example fails clearly rather than timing out.

| Physical rack | Radio it accepts |
|---|---|
| `ACRE_VRC64` | `ACRE_PRC77` |
| `ACRE_VRC103` | `ACRE_PRC117F` |
| `ACRE_VRC110` | `ACRE_PRC152` |
| `ACRE_VRC111` | `ACRE_PRC148` |
| `ACRE_SEM90` | `ACRE_SEM70` |

Third-party rack types are not guessed. They may still be initialized and tuned inline, but WMP will
not claim a replacement radio is compatible without an explicit future profile extension.

## Selecting the intended rack

An assignment row is:

```sqf
[RACK_SELECTOR, NET_KEY_OR_CHANNEL, OPTIONAL_RADIO_ACTION]
```

| Selector | Result |
|---|---|
| `"ALL"` | Tune every already-mounted compatible radio; empty racks are skipped. Do not use this for mounting/removing hardware. |
| `1` | First rack returned by ACRE. Numeric order starts at 1 but is less resilient than a typed selector. |
| `"ACRE_VRC110"` | Every VRC-110 on the object. |
| `["ACRE_VRC110", 1]` | First VRC-110, regardless of unrelated rack order. Recommended. |

The four selectors can use each tuning form below. Hardware changes require one explicit rack (a
number or `[class, occurrence]`) so a beginner cannot accidentally empty every rack on a vehicle.

| Tuning/action value | Result |
|---|---|
| `"AIRGND"` | Resolve the named net through `netSide`, validate the radio family, then tune it. Recommended. |
| `6` | Tune a numbered-channel radio directly to channel 6. This does not create a reusable name. |
| `-1` | Leave tuning unchanged; use this with `UNMOUNT_RADIO` or `REMOVE_RACK`. |
| `"ACRE_PRC152"` as field 3 | Mount or replace the selected removable rack's radio, then apply field 2. |
| `"UNMOUNT_RADIO"` as field 3 | Remove the radio but retain the physical removable rack. |
| `"REMOVE_RACK"` as field 3 | Remove the complete removable rack. |

Examples:

```sqf
// Ensure the first VRC-110 has a PRC-152, then tune it to WEST AIRGND.
[["ACRE_VRC110", 1], "AIRGND", "ACRE_PRC152"]

// Empty the first removable VRC-110 but leave its physical rack installed.
[["ACRE_VRC110", 1], -1, "UNMOUNT_RADIO"]

// Remove the whole first removable VRC-110 rack.
[["ACRE_VRC110", 1], -1, "REMOVE_RACK"]
```

Replacing an occupied radio is an ordered operation: WMP asks ACRE to unmount it, waits for a
synchronized empty rack, mounts the compatible replacement, waits for its unique ID, then tunes and
reads the channel back. Fixed racks are tunable but cannot be emptied, replaced or removed.

## Complete combination checklist

The central `acreConfig.sqf` comments include copyable rows for all supported combinations:

- all five built-in pairs: VRC-64/PRC-77, VRC-103/PRC-117F, VRC-110/PRC-152,
  VRC-111/PRC-148 and SEM90/SEM70;
- an existing mounted radio, a newly-added pre-mounted rack and a newly-added empty rack;
- inside-only, external-only and combined inside/external access;
- all-racks, numeric-position, rack-class and class-plus-occurrence selectors;
- named-net and direct numbered-channel tuning, plus “leave tuning unchanged”;
- mount/replace, unmount-radio and remove-complete-rack actions;
- a reusable central profile, a fully-inline call and a central profile with one inline override.

PRC-77 and SEM70 are the exception to “direct channel”: they use frequency/mode presets. Select an
existing tested ACRE preset in the profile before rack initialisation. WMP intentionally rejects a
decimal frequency assignment rather than claiming it configured a radio that ACRE cannot read back.

## Dedicated-server lifecycle

Rack setup begins on the server, as required by ACRE's public rack APIs:

1. WMP stores the requested setup on the object.
2. If no human ACRE player exists yet, state becomes `WAITING_FOR_PLAYER` and the request is retained.
3. The preset is stored before initialisation.
4. ACRE selects a human client to create the unique IDs, acknowledges them to the server, and
   distributes radio data to other ACRE machines and JIP clients.
5. The server adds or removes physical rack hardware through ACRE's server-only APIs.
6. ACRE 2.14 keeps the mounted-radio data behind those IDs on its selected interface client. WMP
   sends the already-validated tuning plan to that one client, which applies and reads back the
   channel. It does not ask every client to race or give the client authority over the request.
7. The selected client returns one token-bound result; the server records completion and diagnostics.

Repeated identical Eden calls are suppressed both while running and after success. A genuinely new
setup arriving mid-run replaces the queued request and runs after the current worker cleans up.

## Diagnostics

WMP Diagnostics reports both an `acre-vehicle-racks` summary and one `acre-rack-<network ID>` row
per configured object. Each object row shows its class, resolved profile, current owner, initial
rack/radio inventory, every requested job, the final mounted radio/channel read-back, and problems.
The audit mission's **ACRE2: SHOW VEHICLE RACK STATUS** action exposes the same snapshot. RPT lines
beginning `[WMP ACRE RACK]` include the accepted request, inventory and every job result.

| Diagnostic | Meaning and response |
|---|---|
| `WAITING_FOR_ACRE_PLAYER` | Normal dedicated lobby state. Join with an ACRE client; WMP retries automatically. |
| `RACKS_NOT_INITIALISED` | ACRE did not finish within the bounded window. Check client/server ACRE errors. |
| `CLIENT_DATA_NOT_READY` | ACRE published a rack ID but its mounted-radio data did not become readable on the selected ACRE client. |
| `CLIENT_APPLY_TIMEOUT` | The selected ACRE client disconnected or did not return its token-bound result in time; WMP retains the request for retry. |
| `UNKNOWN_RACK_CLASS` | The authored rack class does not exist in loaded ACRE configuration. |
| `INCOMPATIBLE_RADIO` | Rack and radio do not form one of the supported physical pairs. |
| `RADIO_NOT_REMOVABLE` | The assignment tried to replace a fixed radio. Tune it without a replacement classname. |
| `NET_*_NOT_UNIQUE_OR_INCOMPATIBLE` | The named net is absent, ambiguous across sides, or belongs to another radio family. Set `netSide` and use a compatible net. |
| `NO_MOUNTED_RADIO` | An explicitly selected rack is empty. Supply its compatible radio classname. |
| `CHANNEL_OUT_OF_RANGE` | The mounted radio cannot use the requested channel. |
| `FREQUENCY_REQUIRES_PRESET` | A PRC-77/SEM70 rack received a decimal/direct tuning request. Use a tested preset before initialisation. |
| `READBACK_*_EXPECTED_*` | ACRE accepted the call but the resulting channel did not match. Treat this as failure. |

## Ready-made examples

- **ACRE2 Vehicle Radio Rack Example (Minimal):** calls `EXISTING_RACKS_COY`.
- **ACRE2 Vehicle Radio Rack Example (Full):** calls `COMMAND_VEHICLE`, which demonstrates preset,
  idempotent rack addition, compatible mounted radio and verified tuning.

Both examples are lessons as well as ready-made objects. Their Eden comments explain what can be
changed and link back to this page. Do not add `isServer`, `waitUntil`, or client `remoteExec` code to
their Init fields; `Waldo_fnc_ACRE2RackSetup` owns that lifecycle.

## See also

- [ACRE2 Communications Configuration](ACRE-2-Long-Range-Radio-Presetting)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
