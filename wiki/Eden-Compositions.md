# Eden compositions

> **Use this page when:** you want a pre-placed, editable example instead of building a supported
> WMP setup from individual Eden objects.

WMP compositions are shipped as a separate archive. They accelerate mission authoring but do not
include the feature scripts themselves. Install the matching WMP release in the mission first.

The catalogue is split into Foundation, Logistics, Air Operations, Combat Systems, Interface,
Mission Systems and Mission Tools so Eden does not present one undifferentiated list. The full,
current, per-composition list lives in `WMP_Compositions/README.md` inside the pack (its "Current
catalogue" table) — this page explains how to *read* a composition, not a duplicate inventory that
would otherwise go stale as compositions are added.

## Minimal and Full pairs

Every composition with real optional parameters ships as two folders:

- **`..._Minimal`** — the smallest call that actually works: only the function's truly required
  arguments, relying entirely on its own documented defaults for everything else. Start here.
- **`..._Full`** — the same object(s) with every option set explicitly, so a mission maker can see
  and edit each one once the basics make sense.

A composition without real optional parameters (a fixed prop, or a call that's already minimal by
nature) ships as a single unsuffixed folder instead of a redundant pair.

## Locality rule

Composition init fields call the public feature API directly. Each API routes authority to the
server and publishes local/JIP setup where required; beginners should not need to add repetitive
`isServer` wrappers. Local-only Eden actions, such as teleport boarding points, run on each
interface through their repeat-safe setup path. Do not add a locality guard unless that function's
wiki article explicitly requires one.

Every WMP Eden comment includes the direct URL of the matching wiki article. Keep that link when
copying or adapting the example so the next mission maker can recover the parameter and locality
guidance from inside Eden.

## Why some features have no composition

Dynamic AA, Dynamic AO Generation and Airborne Gunship Support all ship compositions — their
registration functions (`Waldo_fnc_DynamicAACreate`, `Waldo_fnc_DynamicAOCreate`,
`Waldo_fnc_GunshipRegister`) self-forward a non-server call to the server exactly like
`Waldo_fnc_Jammer` or `Waldo_fnc_HazardRegisterZone`, which already shipped as compositions, so an
Eden init running on every machine is safe for them too. Only **generated drop zones**
(`Waldo_fnc_ParadropCreateDropZone`) remain excluded for a genuinely different reason: that function
spawns and owns its own aircraft/crew, and an Eden object cannot represent "spawn this on demand" the
way it represents "here is a real placed thing" — use `initServer.sqf` or the "Dynamic Paradrop" ZEN
module instead. The [Halo and Static-Line Paradrop Examples](Vehicle-Actions-&-Paradrop) composition
covers the placed-and-crewed-aircraft case instead.

Player accessibility, treatment feedback, persistence enablement itself (though registering one
specific persistent object is exactly as composable as the systems above — see the Persistence
Object Example composition), UI themes, rally state, terrain-tree felling and automatic AI handlers
likewise do not become clearer or safer when represented by a decorative Eden object. Use their
`MissionConfig` settings, documented public setup call, full audit station or focused Zeus module
instead.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature setup](Feature-Setup-and-Activation)
