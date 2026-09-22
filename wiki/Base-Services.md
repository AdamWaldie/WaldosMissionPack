# Base services

> **Use this page when:** setting up a named base network with object-specific services and teleport destinations.

Base services are off by default. Set `Waldo_BaseServices_Enable` to `true` in `MissionConfig/missionSystemsConfig.sqf`. Put this call in each Eden object's Init field. Objects with the same network ID form one teleport network:

```sqf
[this, "MainBase", "Headquarters", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
```

Put the same `MainBase` ID on the next object, then give it its own label and services. The **Base
Services Example** composition places two stands this way. Both offer save, heal, spectator and
travel. Remove an option from either Init call if that stand should not offer it. Only objects with
`TELEPORT` appear as destinations.

## What players see

Players use ACE Interact on each stand. `SAVE` stores their respawn loadout, including radios.
`HEAL` gives a full ACE heal and a bottom-right notification. `SPECTATE` opens ACE spectator.
Players leave through ACE's spectator controls. `TELEPORT` moves the player to a clear position
using the selected transition. The `TRAVEL` preset shows the destination name. If there is no clear
position, the player stays put and gets a notification. Leave space around each arrival object.

WMP places a 3D label and icon against each object. The label follows an object when it moves.
The server registers the network after settings load and gives each client its ACE actions,
including players who join later. Calling the node function again updates that object.

## Change a network by script

If a script manages all the objects in one network, name them in Eden and call this from
`initServer.sqf`:

```sqf
["MainBase", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "TELEPORT"]],
    [fobRadio, "Forward Base", ["TELEPORT", "SPECTATE"]]
]] call Waldo_fnc_BaseServicesRegister;
```

Each entry is `[object, label, services, optionalIcon, optionalTransition, optionalMarkerOffset]`.
The icon is a `.paa` path. WMP supplies one when you leave it out. The default marker position is
the object's upper surface. For a sign face or unusual model, use a measured model-space offset as
the sixth value, for example `[0, -0.06, 0.18]`. Supply `""` for the icon and transition when you
only want to set the offset. Give nodes the same service list if they should have the same menu.

The optional third argument sets the teleport transition for the whole network. A row's fifth value overrides it for arrivals at that destination:

```sqf
["BaseNetwork", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]],
    [fobRadio, "Forward Base", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"], "", "NIGHT"]
], "TRAVEL"] call Waldo_fnc_BaseServicesRegister;
```

Presets are `STANDARD` (short black fade), `QUICK`, `TRAVEL`, `NIGHT`, `DAYLIGHT` and `NONE`.
`TRAVEL` fades out for three seconds, shows “Traveling to <destination name>...” and fades back over
five seconds. `NIGHT` temporarily lowers exposure. `DAYLIGHT` uses a white fade and bright exposure.

For finer control, replace a preset with `[key, value]` pairs: `[["preset","TRAVEL"],["fadeOut",2],["hold",0.5],["fadeIn",3],["colour","BLACK"],["text","Travelling to the rally point..."],["aperture",15]]`. Times are seconds. `aperture` sets temporary forced exposure from 0.1 to 100. WMP restores the previous aperture after arrival. A new teleport supersedes an unfinished transition.

To change the network, call `Waldo_fnc_BaseServicesRegister` again with the same ID and the complete new row list. An empty list removes the group. WMP replaces its old actions and markers. Register arsenals and quartermasters separately if the base needs them.

Place ZEN **Base Services - Configure Node** directly on an object. It loads the node's current network, label, services and transition for editing. The module can add, update or remove that node. Moving a node to another network removes its old membership. Service choices affect that node alone.

The module requires an active curator and the base-services flag. It does not spawn objects or turn on other features.

Use distinct IDs for independent networks and leave room at each arrival point. ACE and CBA are required.

## See also

- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [Custom 3D World Markers](Custom-3D-World-Markers)
- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
