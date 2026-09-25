# Economy Resource System

> **Use this page when:** you need resource types, crates, capturable zones, collection, or storage limits.

_Associated Files: MissionScripts\EconomySystems\Resource\ (`Waldo_fnc_EcoResource_*`)_

![Resource controls](images/economy/economy-resources.png)

The Resource System is the backbone of [Waldos Economy Systems](Waldos-Economy-Systems). It lets you define arbitrary resources and have players gather them from crates and capturable zones, subject to per-side storage limits. Resources are then spent by the [Research](Waldos-Economy-Systems-Research-System), [Build](Waldos-Economy-Systems-Build-System) and [Buy](Waldos-Economy-Systems-Buy-System) systems.

## Defining resources

| `Waldo_fnc_EcoResource_addResourceType` argument | Type | Default or rule |
| --- | --- | --- |
| Resource name | String | Required; use the same name in costs, crates and zones. |
| Colour | Hex-colour String | `"#FFFFFF"` if omitted. |
| Icon | Image-path String | `""` if omitted; the example uses WMP's default icon helper. |
| Base storage cap | Number | `-1` if omitted, meaning unlimited. |
| Caller label | String | `"Zeus"` if omitted; normally leave this out of mission setup. |

Put authored calls in `MissionConfig/economyConfig.sqf`, which WMP runs on the
server after the economy starts. The catalogue helper publishes its change and
does not return a resource ID or Object to retain.

Each resource has a **name**, a **colour** (used for its markers/labels), a **map icon**, and an optional **per-side storage cap** (`-1` = unlimited). Want Money, Electricity, or Obamium? Define whatever you like.

In Zeus: open **WMP Economy Systems → Resource → Configure Resources**. From script:

```sqf
// [name, "#hexColour", "iconPath", storageCap]
["Money",       "#7BC86A", call Waldo_fnc_EcoResource_getDefaultResourceIcon, -1] call Waldo_fnc_EcoResource_addResourceType;
["Electricity", "#8ED1FC", call Waldo_fnc_EcoResource_getDefaultResourceIcon, 50] call Waldo_fnc_EcoResource_addResourceType;
```

## Resource crates

| `Waldo_fnc_EcoResource_spawnResourceCrate` argument | Type | Default or rule |
| --- | --- | --- |
| Position | Position Array | Required; `getMarkerPos "supply_drop"` is one way to supply it. |
| Contents | Array of `[resource name String, amount Number]` rows | `[]` if omitted. |

The server returns the created Object. A client call forwards the request and
cannot return that Object immediately. Each accepted call creates one case.

A resource crate is a collectable cache (`Land_PlasticCase_01_medium_F`). A player walks up and collects it through ACE or the matching vanilla action; the contained resources are added to that player's side (up to its storage cap). A fully collected crate is deleted immediately. If storage limits prevent taking everything, the crate remains and clearly contains only the uncollected remainder. Spawn one in Zeus (**Resource → Spawn Resource Crate**, then click to place) or from script:

```sqf
// [position, [[resource, amount], ...]]
[getMarkerPos "supply_drop", [["Money", 25], ["Electricity", 10]]] call Waldo_fnc_EcoResource_spawnResourceCrate;
```

## Capturable resource zones

| `Waldo_fnc_EcoResource_createResourceZone` argument | Type | Default or rule |
| --- | --- | --- |
| Position | Position Array | Required. |
| Name | String | Required player-facing zone name. |
| Radius | Number, metres | Required; WMP clamps it to at least `5`. |
| Deposits | Array of `[resource name String, amount per tick Number, deposit cap Number]` rows | Required; `-1` can represent an unlimited deposit. |
| Starting owner | String | `WEST`, `EAST`, `GUER` or `NONE`. |
| Interval | Number, seconds | Required; WMP clamps it to at least `10`. |

The server returns a zone-ID String. A forwarded client call does not return
that ID immediately. Save the ID on the server if a later script needs it.

A zone is an area that **passively generates resources for whichever side owns it**. A side captures it by having units present (and no contesting enemies), after which it ticks resources into that side's storage on an interval.

Each zone has a **name**, **radius**, the **resource rows** it generates `[resource, amountPerTick, depositCap]`, a starting **owner** (`WEST`/`EAST`/`GUER`/`NONE`) and a **tick interval** in seconds. The optional **deposit cap** lets you model a finite deposit that runs dry.

In Zeus: **Resource → Create Resource Zone**. From script:

```sqf
// [position, "Name", radius, [[resource, amountPerTick, depositCap]], "owner", intervalSeconds]
[getMarkerPos "oilfield", "Oil Field", 40, [["Money", 3, 2000]], "NONE", 30] call Waldo_fnc_EcoResource_createResourceZone;
```

Zones get a map marker showing owner and contents; ownership and remaining deposit update live.

## Storage limits

Every resource can have a per-side storage cap. Income above the cap is discarded. Storage buildings in the [Build System](Waldos-Economy-Systems-Build-System) raise a side's cap for a resource.

## If resources do not increase

Confirm the resource name matches the configured catalogue exactly. A crate can only credit the collecting side up to its storage cap. A contested zone does not generate for either side, and a finite deposit stops when empty. Check its owner, tick interval and remaining deposit before increasing the payout.

## See also

* [Setup & Configuration](Waldos-Economy-Systems-Setup-And-Configuration): define the economy from the editor.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
