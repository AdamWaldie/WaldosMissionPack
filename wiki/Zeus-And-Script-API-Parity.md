# Zeus and Script API Parity

> **Use this page when:** you need to translate a Zeus-authored setup into mission script or compare supported options.

WMP's Zeus Enhanced modules are authoring surfaces over the same mission functions available to scripted missions. A module being visible in Zeus is not, by itself, proof that its operation is valid. The repository therefore tracks three separate facts:

1. The module is registered with Zeus Enhanced.
2. Its handler and declared script API are present in `CfgFunctions` and the source pack.
3. Its current implementation has been exercised in Arma on the required client/server path.

The checked-in manifest is `releaseVerificationAndDeployment/zeus_script_parity.json`. Its validation tool rejects missing registrations, missing handlers, invented API names, broken declared bridges and missing required controls. The audit currently covers all 52 categorized core modules and all 19 Economy modules.

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

Do not treat “module registered” as “module worked”. Registration proves only that the curator can
see the entry. A dedicated acceptance run must also see the server receipt/result log, the expected
world or state change, the requesting curator's completion notification, and JIP replay where that
feature owns persistent runtime state.

## Runtime status

Static parity means the module is wired to a real function and its declared controls exist. It does not prove the dialog renders correctly, the selected object is valid, or the dedicated-server locality path succeeds. Runtime acceptance remains part of the full Arma audit mission and must be recorded separately after an in-engine run.

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

## Validation

Run:

```text
python releaseVerificationAndDeployment/zeus_script_parity_checker.py
```

A passing result establishes static registration, declared bridge and API parity only. Use the full audit mission for actual Zeus placement, prompts, server mutation, JIP and cleanup checks. The current server/client log audit specifically guards the long-uptime ID failure that formerly rejected gunship, Dynamic AA/AO, hazard and paradrop IDs, and the client-only Economy/Fortify mutation pattern that formerly worked hosted but not dedicated.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
