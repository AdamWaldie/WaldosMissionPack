_Associated Files: `MissionScripts\Logistics\LogiHelpers\attachedWeapon.sqf`, `Waldo_fnc_VehicleMountedWeapon`_

# Weapon Mounting With Custom Name

Attaches a separate weapon/turret object to a vehicle and wires up "Get In" / "Return" actions so a player can hop between the carrier and the mounted weapon without it counting as a normal turret seat. Handy for a static gun bolted to a truck bed, a mortar on a trailer, or any field-expedient mounted weapon.

The action label is customisable, so the scroll-wheel option can read **"Get In M2"**, **"Get In Mortar"** or whatever you like, instead of a generic prompt.

## What it sets up

* Attaches the turret to the vehicle at its **relative** position (so it rides along correctly).
* Adds a **"Get In _name_"** action both on the turret (when stood next to it) and from inside the vehicle.
* Adds a **"Return To Main Vehicle"** action on the turret to move back into the carrier.
* On ACE, claims the turret (`ace_common_fnc_claim`) so other mods' interactions don't hijack it, and blocks the stray *Unmount / Turn left / Turn right* engine actions that some mods (e.g. IFA3) inject.

## Parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Turret | Object | — | Variable name of the weapon/turret object to mount. |
| 1 | Vehicle | Object | — | Variable name of the carrier vehicle. |
| 2 | Custom name | String | `"Turret"` | Text shown in the **"Get In _X_"** action. |

## Setup in Eden

1. Place the **vehicle** and give it a variable name (e.g. `truck1`).
2. Place the **weapon/turret** object and give it a variable name (e.g. `mountedM2`).
3. Position the turret roughly where it should ride — it is attached at that relative offset.
4. In the **turret's init field**, call the function:

```sqf
[mountedM2, truck1, "M2 Browning"] call Waldo_fnc_VehicleMountedWeapon;
```

## Example

```sqf
// A static gun mounted on a technical, labelled "DShK":
[gunObject, technical1, "DShK"] call Waldo_fnc_VehicleMountedWeapon;
```

Players see **"Get In DShK"** on both the gun and the truck, and **"Return To Main Vehicle"** while manning it.

## See also

* [Simple Mass Attach Items](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Simple-Mass-Attach-Items) — attach decorative/cargo objects to a vehicle
* [Vehicle Actions & Paradrop](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Vehicle-Actions-&-Paradrop)
