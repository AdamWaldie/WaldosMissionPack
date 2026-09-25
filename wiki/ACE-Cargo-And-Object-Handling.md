# ACE Cargo and object handling

> **Use this page when:** setting Drag, Carry, ACE loading size or storage space on an object.

You need ACE and CBA. You do not need a WMP feature flag.

ACE cargo **size** is how much room an object takes when loaded into another object. Set size to `-1` to prevent ACE loading. ACE cargo **space** is how much room an object provides for loaded cargo. Set space to `0` if it should not hold ACE cargo. Drag and Carry are separate choices. The two weight-limit options let ACE ignore its normal limit for that object.

## Change an object during a mission

1. Open Zeus and place WMP's **ACE Cargo - Set Object Handling** module directly on the crate, prop or vehicle.
2. Check the values shown for that object. Change only the settings you want to alter.
3. Press **OK**. To discard your edits, press **Cancel** and open the module again on the object.

![ZEN ACE Cargo and Object Handling dialog with Drag, Carry, size and space controls](images/ace-cargo-object-handling.png)

The dialog reads the selected object's current ACE values when it opens. It does not reuse the last object's settings. Pressing **OK** without making a change leaves the object alone. WMP rounds size and space changed through this module to whole ACE cargo units. Opening the dialog does not round an existing value.

If the object already holds ACE cargo, ACE may expose its remaining space instead of its total capacity. Leave **ACE cargo space** unchanged unless you intend to set a new total.

## Set handling in Eden or a script

Put this in a crate's Eden **Init** field to allow Drag and Carry and make it take one ACE cargo slot:

```sqf
[this, nil, 1, true, true] call Waldo_fnc_SetCargoAttributes;
```

The call runs on the server's copy of the object. WMP waits for ACE's setters if they are not ready when the Init field runs. For an object named in Eden, you can use the same call in `initServer.sqf`:

```sqf
[supplyCrate, nil, 1, true, true] call Waldo_fnc_SetCargoAttributes;
```

The arguments are `[object, cargo space, cargo size, can drag, can carry, ignore drag weight, ignore carry weight]`. Use `nil` for space or size to leave that value unchanged. Specify all four handling Booleans when changing the weight-limit choices:

| Position | Type | Default | Meaning |
|---|---|---|---|
| 0 | Object | Required | Existing crate, prop or vehicle. |
| 1 | Number or `nil` | `nil` | ACE cargo space it provides; `nil` keeps its current value. |
| 2 | Number or `nil` | `nil` | ACE cargo size it uses; `-1` prevents loading. |
| 3 | Boolean | Portable-object default | Allow ACE Drag. |
| 4 | Boolean | Portable-object default | Allow ACE Carry. |
| 5 | Boolean | `false` | Ignore ACE's drag weight limit for this object. |
| 6 | Boolean | `false` | Ignore ACE's carry weight limit for this object. |

The server call returns `true` when it submits valid settings to ACE, or `false` if the object or required ACE addons are unavailable. Eden Init fields, WMP crate issuers, the MHQ and the ZEN module use this helper. ACE replays global settings to joining players. Repeating an unchanged choice sends no further update.

```sqf
[supplyCrate, nil, 1, true, true, true, true] call Waldo_fnc_SetCargoAttributes;
```

For a vehicle that should hold 30 ACE cargo units but that ACE cannot load into another vehicle:

```sqf
[myTruck, 30, -1] call Waldo_fnc_SetCargoAttributes;
```

If you omit the handling Booleans, WMP allows Drag and Carry for portable objects. It disables both for vehicles and static weapons. `nil` for size or space keeps that object's existing value. The function uses ACE's public global setters, so current and joining players receive the resulting handling state.

## WMP-created crates

Quartermaster issues and WMP ZEN supply and medical crates allow Drag and Carry regardless of ACE's weight limits. Each takes one ACE cargo slot. WMP leaves the class's storage space unchanged. Check that space before letting a crate hold other ACE cargo objects.

Starter crates stay in place. WMP disables Drag, Carry and ACE loading for them. You can still change a chosen object's values deliberately with the ZEN module or script call.

WMP also sets ACE cargo space to `4` and loading size to `40` for the vanilla `MRAP_01_base_F` Hunter family during automatic vehicle setup. It leaves Drag and Carry off. That setup does not assign ACE capacity to other vehicle classes.

ACE calculates the time to load each object. To shorten that time for one object, put this in its Eden **Init** field:

```sqf
this setVariable ["ace_cargo_delay", 5, true];
```

That sets a five-second ACE loading delay for that object. Changing a crate's cargo size does not change the loading time of a vehicle placed inside it. See the [ACE Cargo framework](https://ace3.acemod.org/wiki/framework/cargo-framework) for ACE's cargo rules.

ACE handling alone does not register an object for [Supply Transfers](Supply-Transfers) or enable [Physical Cargo](Physical-Cargo). Follow each feature's setup if you need those actions.

## If a setting does not stick

- **ZEN rejects the object:** Place the module directly on the object, confirm it still exists, and check that ACE Cargo and ACE Dragging are loaded.
- **A newly issued crate shows its old ACE size:** Reopen the module on that specific object. The dialog reads its current values. A different crate may have different settings.
- **Cargo time still feels long:** ACE calculates loading time separately from WMP's size setting. Set `ace_cargo_delay` on the object being loaded if your mission needs a shorter delay.
- **No physical mount or transfer menu:** Those are separate features. Follow their linked setup guides.

## See also

- [Quartermaster](Quartermaster)
- [Logistics and loadout-derived crates](Logistics-System,-Starter-Crates-And-Quartermaster)
- [Supply Transfers](Supply-Transfers)
- [Physical Cargo](Physical-Cargo)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
