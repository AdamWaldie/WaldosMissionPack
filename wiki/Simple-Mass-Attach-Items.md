_Associated Files: `MissionScripts\Logistics\LogiHelpers\massAttachItems.sqf`, `Waldo_fnc_MassAttachRelative`_

# Simple Mass Attach Items

Attaches a whole group of editor-placed objects to one "parent" object in a single call, keeping each item's **relative position** to the parent. Use it to bolt scenery, cargo, decoration or props onto a vehicle (or any object) so they travel with it — sandbags on a truck, jerry cans on a quad, crates lashed to a boat, and so on.

Objects are gathered automatically by a synced **Game Logic**, so you never list classnames or offsets by hand: place the props where you want them, sync them, and call the function.

## Parameters

| # | Parameter | Type | Purpose |
|---|---|---|---|
| 0 | Target object | Object | Variable name of the object everything is attached **to**. |

## Setup in Eden

1. Place the **parent** object (vehicle or object) you want everything attached to.
2. Place a **Game Logic** as close as possible to the parent (found near the Modules menu).
3. Place every object you want attached, positioned where it should end up.
4. If the parent is a vehicle and a prop should rest on the ground, raise it ~1 ft to allow for the vehicle's suspension settling once the mission loads.
5. Select all the props, right-click → **Synchronise** them to the Game Logic.
6. In the **parent object's init field**, call the function:

```sqf
[this] call Waldo_fnc_MassAttachRelative;
```

The script finds the nearest Logic to the parent, reads everything synced to it, and attaches each object at its current relative position.

## Notes

* Attachment uses `BIS_fnc_attachToRelative`, so objects keep the exact offset/rotation you placed them at.
* For a single **mannable** weapon with get-in actions, use [Weapon Mounting With Custom Name](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Weapon-Mounting-With-Custom-Name) instead — this function is for static/decorative attachments.

## See also

* [Weapon Mounting With Custom Name](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Weapon-Mounting-With-Custom-Name)
* [Mobile Command Post](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mobile-Command-Post-With-Integrated-Logistics-System) — also uses the synced-Logic pattern for deployable objects
* [Construction Objects](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Construction-Objects)
