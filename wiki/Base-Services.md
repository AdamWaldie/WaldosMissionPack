# Base services

> **Use this page when:** placing save, heal, spectator or travel points in a named base network.

Base services put save, heal, spectator and travel actions on objects you place in Eden. The feature is off by default and requires ACE and CBA.

## Place two service points

1. Set `Waldo_BaseServices_Enable` to `true` in `MissionConfig/missionSystemsConfig.sqf`.
2. Place two objects in Eden. A desk, laptop or sign stand will work.
3. Put this in the first object's **Init** field:

   ```sqf
   [this, "MainBase", "Headquarters", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
   ```

4. Put this in the second object's **Init** field:

   ```sqf
   [this, "MainBase", "Forward Base", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
   ```

Both objects now belong to the `MainBase` travel network. Give each object its own label. Remove a service name from an object's list if it should not offer that action. Only objects with `TELEPORT` appear as destinations. The **Base Services Example** Eden composition includes two configured stands.

Players open ACE Interact on a stand. `SAVE` stores their respawn loadout, including radio settings.
`HEAL` gives a full ACE heal and shows a notification. `SPECTATE` opens ACE spectator. Players leave
through ACE's spectator controls. `TELEPORT` moves the player to another node in the network.

WMP puts a 3D label and icon against each stand. They follow the object if it moves. The server registers the nodes after settings load, and players who join later receive the same actions and markers. Calling `Waldo_fnc_BaseServicesRegisterNode` again updates that node.

## Place travel destinations

Leave clear ground near each destination. WMP checks for a safe arrival position, starting two metres in front of the object and searching within six metres. It does not use the object's exact position or floor height. If the search fails, the player stays where they are and gets a notification. Test any destination inside a building or above ground level in Arma.

The default transition uses a short black fade. To change a destination's transition, add a preset after its service list:

```sqf
[this, "MainBase", "Forward Base", ["TELEPORT"], "", "NIGHT"] call Waldo_fnc_BaseServicesRegisterNode;
```

Presets are `STANDARD`, `QUICK`, `TRAVEL`, `NIGHT`, `DAYLIGHT` and `NONE`. `TRAVEL` fades out for three
seconds. It shows “Traveling to <destination name>...” and fades back over five seconds. `NIGHT`
temporarily lowers exposure. `DAYLIGHT` uses a white fade and bright exposure. WMP restores the
previous aperture after arrival.

## Manage a whole network by script

If your mission already names its objects in Eden, register the whole network from `initServer.sqf`:

```sqf
["MainBase", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "TELEPORT"]],
    [fobRadio, "Forward Base", ["TELEPORT", "SPECTATE"]]
]] call Waldo_fnc_BaseServicesRegister;
```

Each row accepts `[object, label, services, optionalIcon, optionalTransition, optionalMarkerOffset]`. The icon is a `.paa` path. Leave it out to use WMP's icon. The marker sits against the object's upper surface by default. For an unusual sign or model, set the sixth value to a measured model-space offset such as `[0, -0.06, 0.18]`. Use `""` for the icon and transition when you only need the offset.

An optional third argument sets the transition for every destination in the network. A row's fifth value overrides it for that destination:

```sqf
["MainBase", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]],
    [fobRadio, "Forward Base", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"], "", "NIGHT"]
], "TRAVEL"] call Waldo_fnc_BaseServicesRegister;
```

For custom timing and exposure, replace a preset with `[key, value]` pairs:

```sqf
[["preset", "TRAVEL"], ["fadeOut", 2], ["hold", 0.5], ["fadeIn", 3],
 ["colour", "BLACK"], ["text", "Travelling to the rally point..."], ["aperture", 15]]
```

Times are seconds. `aperture` accepts 0.1 to 100. A new teleport supersedes a transition still in progress. Call `Waldo_fnc_BaseServicesRegister` again with the same ID and the complete new row list to update a network. Pass an empty row list to remove it. WMP replaces the old actions and markers.

## Change a node during play

With Zeus Enhanced, place ZEN **Base Services - Configure Node** directly on the object. It shows
that node's current network, label, services and transition. Add, update or remove the node there.
Moving it to another network removes its old membership.

The module needs an active curator and
the base-services flag. It edits existing objects only. Set up quartermasters and arsenals separately.

## See also

- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [Custom 3D World Markers](Custom-3D-World-Markers)
- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
