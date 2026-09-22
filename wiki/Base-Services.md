# Base services

> **Use this page when:** setting up a named base network with object-specific services and teleport destinations.

Base services are off by default. Set `Waldo_BaseServices_Enable` to `true` in `MissionConfig/missionSystemsConfig.sqf`. Put this call in each Eden object's Init field. Objects with the same network ID form one teleport network:

```sqf
[this, "MainBase", "Headquarters", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
```

The Eden **Base Services Example** composition places two stands in a `MainBase` network. Both show save, heal, spectator and teleport by default. Remove services from an individual stand when it should offer less.

Use the same `MainBase` ID on the next object, with its own label and services. The call updates only that object, regardless of Eden Init order. WMP ignores non-server calls, waits for shared settings and sends the complete network to clients, including JIP. Optional fifth through seventh arguments set the icon, arrival transition and model-space marker offset. Call the function again on the server to edit a node. Remove one through ZEN **Base Services - Configure Node**, or replace the whole network with the call below.

For scripts that manage an entire network at once, place named objects and register them from `initServer.sqf`:

```sqf
["MainBase", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "TELEPORT"]],
    [fobRadio, "Forward Base", ["TELEPORT", "SPECTATE"]]
]] call Waldo_fnc_BaseServicesRegister;
```

Each row is `[object, label, services, optionalIcon, optionalTransition, optionalMarkerOffset]`. Valid services are `SAVE`, `HEAL`, `SPECTATE` and `TELEPORT`. Only objects with `TELEPORT` appear as destinations. The optional icon is a `.paa` path. WMP uses its default icon when omitted. The marker sits at the object's upper surface by default.

For a sign face or unusual model, measure a model-space offset on that object. Pass it as the sixth value, for example `[0, -0.06, 0.18]`. Use `""` for the icon and transition if you only need the offset. Give nodes the same service list if they should have the same menu.

The optional third argument sets the teleport transition for the whole network. A row's fifth value overrides it for arrivals at that destination:

```sqf
["BaseNetwork", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]],
    [fobRadio, "Forward Base", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"], "", "NIGHT"]
], "TRAVEL"] call Waldo_fnc_BaseServicesRegister;
```

Presets are `STANDARD` (short black fade), `QUICK`, `TRAVEL`, `NIGHT`, `DAYLIGHT` and `NONE`. `TRAVEL` fades out for three seconds, shows “Traveling to <destination name>...” and fades back over five seconds. `NIGHT` temporarily lowers exposure; `DAYLIGHT` uses a white fade and bright exposure.

For finer control, replace a preset with `[key, value]` pairs: `[["preset","TRAVEL"],["fadeOut",2],["hold",0.5],["fadeIn",3],["colour","BLACK"],["text","Travelling to the rally point..."],["aperture",15]]`. Times are seconds. `aperture` sets temporary forced exposure from 0.1 to 100. WMP restores the previous aperture after arrival. A new teleport supersedes an unfinished transition.

WMP's 3D marker renderer keeps the label and icon on a moving object. Each interface client installs ACE actions, including JIP players. Teleport moves the player after fade-out.

`SAVE` calls WMP's respawn-loadout save, including radio handling. `HEAL` uses ACE's full-heal function and shows a WMP notification at the bottom right. `SPECTATE` enters ACE spectator. Players leave through ACE's controls. The server checks teleport requests, then the player's machine finds a clear arrival position. If it cannot find one, the player stays put and receives a WMP notification.

To change the network, call `Waldo_fnc_BaseServicesRegister` again with the same ID and the complete new row list. An empty list removes the group. WMP replaces its old actions and markers. Register arsenals and quartermasters separately if the base needs them.

Place ZEN **Base Services - Configure Node** directly on an object. It loads the node's current network, label, services and transition for editing. The module can add, update or remove that node. Moving a node to another network removes its old membership. Service choices affect that node alone.

The module requires an active curator and the base-services flag. It does not spawn objects or turn on other features.

Use distinct IDs for independent networks and leave room at each arrival point. ACE and CBA are required. Dedicated-server and JIP interaction acceptance is still outstanding.

## See also

- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [Custom 3D World Markers](Custom-3D-World-Markers)
- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
