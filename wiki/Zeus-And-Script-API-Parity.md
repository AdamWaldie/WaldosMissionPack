# Zeus and Script API Parity

> **Use this page when:** you need to translate a Zeus-authored setup into mission script or compare supported options.

WMP's Zeus Enhanced modules are authoring surfaces over the same mission functions available to scripted missions. A module being visible in Zeus is not, by itself, proof that its operation is valid. The repository therefore tracks three separate facts:

1. The module is registered with Zeus Enhanced.
2. Its handler and declared script API are present in `CfgFunctions` and the source pack.
3. Its current implementation has been exercised in Arma on the required client/server path.

The checked-in manifest is `releaseVerificationAndDeployment/zeus_script_parity.json`. Its validation tool rejects missing registrations, missing handlers, invented API names and missing required controls. The audit currently covers all 41 categorized core modules and all 19 Economy modules.

## Direct modules and adapters

There are two supported implementation shapes:

- **Direct:** Zeus calls the same public function used by mission scripts, sometimes through `remoteExec` to preserve server authority.
- **Adapter:** Zeus collects a position, object or form values, validates them, then calls the public function. Supply crates, Economy catalogue editors and similar authoring tools need this thin translation layer.

Adapters must not create a second rules implementation. Their manifest entry identifies the public API they reach and explains the translation.

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

A passing result establishes static registration and API parity only. Use the full audit mission for actual Zeus placement, prompts, server mutation, JIP and cleanup checks.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
