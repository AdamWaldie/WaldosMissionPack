# Base services (save / heal / spectate / teleport points)

Puts **SAVE**, **HEAL**, **SPECTATE** and **TELEPORT** ACE actions on placed
objects grouped into named travel networks. Requires ACE + CBA. **Off by
default.** Wiki: `wiki/Base-Services.md`.

## Config (`MissionConfig\missionSystemsConfig.sqf`, `shared` row)

```sqf
["Waldo_BaseServices_Enable", false],   // BOOL: explicitly registered ACE service-object networks
```

Enabling it places nothing — objects still need registering.

## Per-object setup (Eden Init, no `isServer` wrapper)

```sqf
[this, "MainBase", "Headquarters", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
// [object, networkId, label, services, icon ("" = WMP icon), transition]
[this, "MainBase", "Forward Base", ["TELEPORT"], "", "NIGHT"] call Waldo_fnc_BaseServicesRegisterNode;
```

Objects sharing a network ID form one travel network; each needs its own
label. Only nodes offering `TELEPORT` appear as destinations. Calling again
updates that node.

- `SAVE` — stores the respawn loadout including radio settings (see `respawn.md`).
- `HEAL` — full ACE heal + notification.
- `SPECTATE` — opens ACE spectator; players leave via ACE's spectator controls.
- `TELEPORT` — moves the player to another node in the network.

Each node gets an object-following 3D label/icon (see `3d-markers.md`).
The server registers nodes after settings load; JIP players receive the
same actions and markers.

## Whole-network registration (`initServer.sqf`, named objects)

```sqf
["MainBase", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]],
    [fobRadio, "Forward Base", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"], "", "NIGHT"]
], "TRAVEL"] call Waldo_fnc_BaseServicesRegister;
// row: [object, label, services, optionalIcon, optionalTransition, optionalMarkerOffset]
// 3rd arg: default transition for the whole network; a row's 5th value overrides it
```

Call again with the same ID and the complete new row list to update; pass
an empty row list to remove the network. The sixth row value is a measured
model-space marker offset such as `[0, -0.06, 0.18]` (use `""` for icon
and transition when only the offset is needed).

## Transitions

Presets: `STANDARD` (default short black fade), `QUICK`, `TRAVEL` (3 s fade
out, "Traveling to <destination>...", 5 s fade in), `NIGHT` (temporarily
lowered exposure), `DAYLIGHT` (white fade, bright exposure), `NONE`.
Custom: replace the preset with `[key, value]` pairs:

```sqf
[["preset", "TRAVEL"], ["fadeOut", 2], ["hold", 0.5], ["fadeIn", 3],
 ["colour", "BLACK"], ["text", "Travelling to the rally point..."], ["aperture", 15]]
```

Times in seconds; `aperture` 0.1–100; previous aperture restored after
arrival. A new teleport supersedes one in progress.

## Arrival position gotcha

WMP searches for a safe arrival spot starting 2 m in front of the object,
within 6 m — never the object's exact position or floor height. If the
search fails the player stays put and is notified. Leave clear ground near
each destination; test anything inside a building or above ground level.

## Zeus: Base Services - Configure Node (WMP Mission Flow)

Place directly on the object: shows its current network, label, services
and transition; add, update or remove the node. Moving it to another
network removes the old membership. Needs an active curator and the
feature flag; edits existing objects only (set up quartermasters/arsenals
separately).

## Eden composition

**Base Services Example** — two configured stands in one network with
save, heal, spectator and two-way travel. Still needs
`Waldo_BaseServices_Enable = true`.
