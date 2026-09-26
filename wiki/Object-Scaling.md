# Object Scaling

> **Use this page when:** an editor prop needs a larger or smaller decorative form during a mission.

Object Scaling changes a Simple Object or attached object's uniform scale. An ordinary object may require conversion to a Simple Object first. Conversion is destructive: it replaces the original object and removes its simulation, damage, inventory, crew and object-bound actions. Do not use it on a functional crate or vehicle.

## Scale one prop

For an already suitable Simple Object, use the **Scale Object** Zeus module on the target and choose its scale. For a scripted decoration, call on the server:

```sqf
private _scaledStatue = [statue, 1.75, true] call Waldo_fnc_ObjectScale;
```

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | Existing Simple Object or attached decorative object. |
| 1 | Number | `1` | Uniform size multiplier. WMP clamps it to the configured minimum and maximum. |
| 2 | Boolean | `false` | Set `true` only to replace an unsupported ordinary object with a non-functional Simple Object. |

On the server, the function returns the scaled object or `objNull` if it rejects the request. Store that return value when conversion is on, because the original object reference is replaced. A client call forwards the request and immediately returns the original object, so use a server call when you need the authoritative replacement reference. The third argument is appropriate only when you deliberately accept a non-functional decorative replacement.

## Limits and placement

Edit the existing rows in `MissionConfig/logisticsConfig.sqf` if your mission requires different limits:

| Setting | Type | Shipped value | What it changes |
|---|---|---|---|
| `Waldo_ObjectScaling_Minimum` | Number | `0.1` | Smallest positive scale accepted. |
| `Waldo_ObjectScaling_Maximum` | Number | `10` | Largest accepted scale. Keep it at or above the minimum. |
| `Waldo_ObjectScaling_AllowClientRequests` | Boolean | `false` | Advanced: permits non-curator client requests. Leave off for ordinary missions. |

A `1.75` scale makes the prop 75 percent larger. Apply direction and orientation before scaling, because Arma's orientation commands can reset scale. The ZEN module requires curator authority for remote changes.

For batches, tag supported objects with `Waldo_ObjectScale` and use `Waldo_fnc_ObjectScaleTagged`. See [Optional Feature Extensions](Optional-Feature-Extensions#scaling-and-transforms) for copy, reset and placement helpers.

## If the scale does not stick

Check whether the object is a Simple Object or attached object, whether the requested scale is inside the mission limits, and whether another script changes its orientation afterward. Some assets' visible and collision geometry disagree at unusual scales. Test them in Arma before release.

## See also

- [Simple Mass Attach Items](Simple-Mass-Attach-Items)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
