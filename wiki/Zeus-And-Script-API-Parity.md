# Zeus and Script API Parity

> **Use this page when:** you need to translate a Zeus-authored setup into mission script or compare supported options.

WMP's Zeus Enhanced modules are authoring surfaces over the same mission functions available to
scripted missions. A module being visible in Zeus does not mean it has configured the selected
object. Check its completion notification and the resulting object or setting.

## Direct modules and adapters

There are two supported implementation shapes:

- **Direct:** Zeus calls the same public function used by mission scripts, sometimes through `remoteExec` to preserve server authority.
- **Adapter:** Zeus collects a position, object or form values, validates them, then calls the public function. Supply crates, Economy catalogue editors and similar authoring tools need this thin translation layer.

Adapters must not create a second rules implementation. Their manifest entry identifies the public API they reach and explains the translation.

## Dedicated-server execution rule

ZEN dialogs and object selection run on the curator's interface client. Shared catalogues, world
objects, AI groups, registries and mission state do not. A supported mutation therefore follows
this path:

1. The curator client opens the friendly dialog and submits plain data plus the requesting player.
2. A server function checks that the network owner matches that player and that the player owns an
   assigned curator logic.
3. The server validates the selected object/configuration, calls the ordinary public script API,
   publishes any JIP state, and returns a visible success or failure notification to that curator.

The core runtime bridge covers recovery workshops/vehicles/carriers, resupply, persistence,
hazards, tactical displays, rally and other live settings. Dedicated bridges cover crate creation,
jammers, Fortify, EMP, trackers, Dynamic AA/AO, gunships and paradrop. Every Economy authoring or
placement mutation now uses its shared curator-authenticated server request. Building a setup text
for the clipboard is deliberately interface-local because it does not change the mission.


## Jammer example

The script API exposes radius, sides, frequency bands, falloff, strength, initial state, map marker, directional sector, pulse duty, UAV effect and per-emitter curator overlay:

```sqf
[
    this,
    600,
    "WEST",
    [[30, 88]],
    100,
    0.8,
    true,
    false,
    [90, 60],
    [4, 2],
    true,
    true
] call Waldo_fnc_Jammer;
```

The **Jammer: Place New Emitter** Zeus dialog exposes the same choices plus the physical emitter classname. The classname is an adapter concern: Zeus must create an object before it can call `Waldo_fnc_Jammer`, while a scripted mission normally supplies an existing object.


<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
