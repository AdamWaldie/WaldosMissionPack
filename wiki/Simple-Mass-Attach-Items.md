# Simple Mass Attach Items

> **Use this page when:** you need to attach multiple synchronized objects to a parent object in Eden.

_Associated Files: `MissionScripts\Logistics\LogiHelpers\massAttachItems.sqf`, `Waldo_fnc_MassAttachRelative`_


Attaches editor-placed objects to one parent while keeping their relative positions. This is a manual Eden layout helper for scenery and props. It does not use [Physical Cargo](Physical-Cargo), check collision safety, manage seats or provide pickup and unloading actions.

The helper reads objects synchronized to the nearest **Game Logic**. Place the props where you want them, synchronize them to that Logic and call the function on the parent.

## Parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Target object | Object | Required | Existing parent object to which the Logic's children attach. |

The function returns no useful value. It has no server authority check or explicit JIP replay. Eden Init runs for joining clients, but dynamically created parents need a setup path for those clients. Test movement and locality changes with a real vehicle before relying on a mounted layout.

## Setup in Eden

1. Place the **parent** object (vehicle or object) you want everything attached to.
2. Place a **Game Logic** as close as possible to the parent (found near the Modules menu).
3. Place every object you want attached, positioned where it should end up.
4. On a vehicle, leave room for its suspension to settle after the mission loads. Test the placed props in game.
5. Select all the props, right-click → **Synchronise** them to the Game Logic.
6. In the **parent object's init field**, call the function:

```sqf
[this] call Waldo_fnc_MassAttachRelative;
```

The script finds the nearest Logic to the parent, reads everything synced to it, and attaches each object at its current relative position. Keep unrelated Logics away from the parent so the nearest one is unambiguous.

## Notes

* Attachment uses `BIS_fnc_attachToRelative`, so objects keep the exact offset/rotation you placed them at.
* For a separate **mannable** weapon with get-in actions, see the [legacy weapon-mounting helper](Weapon-Mounting-With-Custom-Name) and its safety limits.

## If an item attaches in the wrong place

Check the parent object's Init call, the synchronised children and their starting positions in Eden. This helper keeps the authored relative placement. It does not find a vehicle mount point. Move the parent after mission start to check the layout.

## See also

* [Weapon Mounting With Custom Name](Weapon-Mounting-With-Custom-Name)
* [Mobile Command Post](Mobile-Command-Post-With-Integrated-Logistics-System): also uses the synced-Logic pattern for deployable objects
* [Construction Objects](Construction-Objects)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
