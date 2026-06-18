_Associated Files: MissionScripts\EconomySystems\Resource\ (`Waldo_fnc_EcoResource_*`)_

The Resource System is the backbone of [Waldos Economy Systems](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems). It lets you define arbitrary resources and have players gather them from crates and capturable zones, subject to per-side storage limits. Resources are then spent by the [Research](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Research-System), [Build](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Build-System) and [Buy](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Buy-System) systems.

## Defining resources

Each resource has a **name**, a **colour** (used for its markers/labels), a **map icon**, and an optional **per-side storage cap** (`-1` = unlimited). Want Money, Electricity, or Obamium? Define whatever you like.

In Zeus: open **Waldos Economy Systems → Resource → Configure Resources**. From script:

```sqf
// [name, "#hexColour", "iconPath", storageCap]
["Money",       "#7BC86A", call Waldo_fnc_EcoResource_getDefaultResourceIcon, -1] call Waldo_fnc_EcoResource_addResourceType;
["Electricity", "#8ED1FC", call Waldo_fnc_EcoResource_getDefaultResourceIcon, 50] call Waldo_fnc_EcoResource_addResourceType;
```

## Resource crates

A resource crate is a collectable cache (`Land_PlasticCase_01_medium_F`). A player walks up and collects it via the ACE interaction menu; the contained resources are added to that player's side (up to its storage cap). Spawn one in Zeus (**Resource → Spawn Resource Crate**, then click to place) or from script:

```sqf
// [position, [[resource, amount], ...]]
[getMarkerPos "supply_drop", [["Money", 25], ["Electricity", 10]]] call Waldo_fnc_EcoResource_spawnResourceCrate;
```

## Capturable resource zones

A zone is an area that **passively generates resources for whichever side owns it**. A side captures it by having units present (and no contesting enemies), after which it ticks resources into that side's storage on an interval.

Each zone has a **name**, **radius**, the **resource rows** it generates `[resource, amountPerTick, depositCap]`, a starting **owner** (`WEST`/`EAST`/`GUER`/`NONE`) and a **tick interval** in seconds. The optional **deposit cap** lets you model a finite deposit that runs dry.

In Zeus: **Resource → Create Resource Zone**. From script:

```sqf
// [position, "Name", radius, [[resource, amountPerTick, depositCap]], "owner", intervalSeconds]
[getMarkerPos "oilfield", "Oil Field", 40, [["Money", 3, 2000]], "NONE", 30] call Waldo_fnc_EcoResource_createResourceZone;
```

Zones get a map marker showing owner and contents; ownership and remaining deposit update live.

## Storage limits

Every resource can have a per-side storage cap. Income that would exceed the cap is discarded, so storage buildings (see the [Build System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Build-System)) become meaningful — they raise a side's cap for a resource.

## See also

* [Setup & Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Setup-And-Configuration) — defining all of this from the editor.
