# Weapon Mounting with a Custom Name

> **Use this page when:** you need to mount a weapon on an object and expose it through a named interaction.

_Associated Files: `MissionScripts\Logistics\LogiHelpers\attachedWeapon.sqf`, `Waldo_fnc_VehicleMountedWeapon`_

## What this helper does

This older helper attaches a separate static weapon to a vehicle and adds vanilla **Get In** and **Return** actions. It is independent of [Physical Cargo](Physical-Cargo). It does not check clearance or physics safety, so test the exact vehicle and weapon together before using it in a live mission.

The name controls the scroll-wheel label, such as **Get In M2**.

## What it sets up

* Attaches the turret to the vehicle at its **relative** position (so it rides along correctly).
* Adds a **"Get In _name_"** action both on the turret (when stood next to it) and from inside the vehicle.
* Adds a **"Return To Main Vehicle"** action on the turret to move back into the carrier.
* When ACE is present, calls `ace_common_fnc_claim` for the turret.
* Replaces the client's global action UI handler to block **Unmount**, **Turn left** and **Turn right** labels. That handler can conflict with another mission script that uses the same slot.

## Parameters

| # | Parameter | Type | Default | Purpose |
|---|---|---|---|---|
| 0 | Turret | Object | Required | Existing static weapon object to mount. |
| 1 | Vehicle | Object | Required | Existing carrier vehicle. |
| 2 | Custom name | String | `"Turret"` | Text shown in the **"Get In _X_"** action. |

The call returns the local action ID of the final **Return To Main Vehicle** action. It has no server-owned mount record, collision rollback, or duplicate-action guard. Eden Init runs for joining players. Set up a gun and carrier created during play on each joining interface.

## Setup in Eden

1. Place the **vehicle** and give it a variable name (e.g. `truck1`).
2. Place the **weapon/turret** object and give it a variable name (e.g. `mountedM2`).
3. Position the turret where it should ride. The helper keeps that relative offset.
4. In the **turret's init field**, call the function:

```sqf
[mountedM2, truck1, "M2 Browning"] call Waldo_fnc_VehicleMountedWeapon;
```

## Example

```sqf
// A static gun mounted on a technical, labelled "DShK":
[gunObject, technical1, "DShK"] call Waldo_fnc_VehicleMountedWeapon;
```

Players see **Get In DShK** on both objects and **Return To Main Vehicle** while manning the gun. Test entry, exit, movement and damage with the chosen mod classes. This helper does not make an unsafe attachment safe.

## If the named action is missing

Check that the weapon and carrier are the exact objects passed to the call. Repeated calls can add duplicate actions. If the vehicle flips or collides with the gun, stop using this pair. The working-static-weapon branch of [Physical Cargo](Physical-Cargo) was retired.

## See also

* [Simple Mass Attach Items](Simple-Mass-Attach-Items): attach decorative objects to a vehicle
* [Paradrop](Paradrop)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
