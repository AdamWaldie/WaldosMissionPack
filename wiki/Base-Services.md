# Base services

> **Use this page when:** you want several named base objects to offer selected services and a shared teleport network.

Base services are off by default. Set `Waldo_BaseServices_Enable` to `true` in `MissionConfig/missionSystemsConfig.sqf`. The simplest setup is to put one call in each Eden object's Init field; objects with the same network ID form a base together:

```sqf
[this, "MainBase", "Headquarters", ["SAVE", "HEAL", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
```

On another object, use the same `MainBase` ID and its own label/services. The node call adds or updates only that object, so object Init order cannot replace the other nodes. Eden runs Init on every machine and again for JIP; WMP ignores non-server calls, waits for shared settings on the server, and republishes the resulting full network. Optional fifth through seventh arguments are icon, destination transition preset, and model-space marker offset. To change a node at runtime, call it again on the server with the same object and group ID. To remove one node, use the ZEN **Base Services - Configure Node** module's remove option, or replace the whole network with the API below.

For scripts that manage an entire network at once, place named objects and register them from `initServer.sqf`:

```sqf
["MainBase", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "TELEPORT"]],
    [fobRadio, "Forward Base", ["TELEPORT", "SPECTATE"]]
]] call Waldo_fnc_BaseServicesRegister;
```

Each row is `[object, label, services, optionalIcon, optionalTransition, optionalMarkerOffset]`. Valid services are `SAVE`, `HEAL`, `SPECTATE` and `TELEPORT`. Only objects with `TELEPORT` become destinations. The optional icon is a `.paa` path. If omitted, WMP uses its default interaction icon. The marker defaults to the object's upper surface rather than floating a fixed half-metre above it. For a sign face or unusual model, supply a three-number model-space marker offset as the sixth value, for example `[0, -0.06, 0.18]`; measure it on the actual object. Use `""` for the optional icon and transition if you only want to supply an offset. Objects can have different options when you deliberately give them different service lists; give them the same list for the same menu at each base, as the QA stations now do.

The optional third argument sets the teleport transition for the whole network. A row's fifth value overrides it for arrivals at that destination:

```sqf
["BaseNetwork", [
    [hqDesk, "Main HQ", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]],
    [fobRadio, "Forward Base", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"], "", "NIGHT"]
], "TRAVEL"] call Waldo_fnc_BaseServicesRegister;
```

Presets are `STANDARD` (short black fade), `QUICK`, `TRAVEL` (three-second fade to black, “Traveling to <destination name>...” caption, five-second fade back), `NIGHT` (slower black fade with temporary low-light exposure), `DAYLIGHT` (white fade with temporary bright exposure), and `NONE`. For finer control, replace a preset with an array of `[key, value]` pairs: `[["preset","TRAVEL"],["fadeOut",2],["hold",0.5],["fadeIn",3],["colour","BLACK"],["text","Travelling to the rally point..."],["aperture",15]]`. Times are seconds; `aperture` is an optional temporary forced exposure (0.1–100). WMP restores the previous aperture setting after arrival. A new teleport supersedes an unfinished transition.

WMP's shared 3D marker renderer keeps the label and icon on the object when it moves. Each interface client installs ACE actions, including players who join later. The player moves only after fade-out, so the source scene is not exposed during the transition.

`SAVE` calls WMP's existing respawn-loadout save, which includes the pack's radio handling. `HEAL` uses ACE's full-heal function and shows a WMP success notification at the bottom right. `SPECTATE` enters ACE spectator; leaving spectator uses ACE's own controls. Teleport requests are checked on the server, then the player's machine finds a clear arrival position near the destination. If it cannot find one, the player stays put and receives a WMP notification.

To change the network, call `Waldo_fnc_BaseServicesRegister` again with the same ID and the complete new row list. Passing an empty row list removes that group. Re-registration replaces its old actions and markers. Existing arsenals and quartermasters remain separate features. Registering a base object never enables them.

ZEN **Base Services - Configure Node** must be placed directly on an object. It prefills an existing node's network, label, services and transition for editing. It can add/update a node or remove that object from a named network. Reassigning an object to a different named network removes its old membership. Its service choices affect only that node. It requires an active curator and the base-services flag; it does not spawn objects or enable unrelated services.

Use distinct IDs for independent networks. Keep arrival areas clear. The interactions require ACE and CBA. Dedicated-server and JIP interaction acceptance is still required for this new system.

## See also

- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [Custom 3D World Markers](Custom-3D-World-Markers)
- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
