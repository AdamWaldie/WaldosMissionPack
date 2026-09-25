# Object Scaling

> **Use this page when:** an editor prop needs a larger or smaller decorative form during a mission.

Object Scaling changes a Simple Object or attached object's uniform scale. An ordinary object may require conversion to a Simple Object first. Conversion is destructive: it replaces the original object and removes its simulation, damage, inventory, crew and object-bound actions. Do not use it on a functional crate or vehicle.

## Scale one prop

For an already suitable Simple Object, use the **Scale Object** Zeus module on the target and choose its scale. For a scripted decoration, call on the server:

```sqf
private _scaledStatue = [statue, 1.75, true] call Waldo_fnc_ObjectScale;
```

The arguments are `[object, scale, allowDecorativeConversion]`. The function returns the resulting object. Store that return value when the third argument is `true`, because conversion replaces the original object reference. The third argument is appropriate only when you deliberately accept a non-functional decorative replacement.

## Limits and placement

Edit the existing `Waldo_ObjectScaling_Minimum` and `Waldo_ObjectScaling_Maximum` rows in `MissionConfig/logisticsConfig.sqf` if your mission requires a different allowed range. The shipped range is `0.1` to `10`. A `1.75` scale makes the prop 75 percent larger. Apply direction and orientation before scaling, because Arma's orientation commands can reset scale. The ZEN module requires curator authority for remote changes.

For batches, tag supported objects with `Waldo_ObjectScale` and use `Waldo_fnc_ObjectScaleTagged`. See [Optional Feature Extensions](Optional-Feature-Extensions#scaling-and-transforms) for copy, reset and placement helpers.

## If the scale does not stick

Check whether the object is a Simple Object or attached object, whether the requested scale is inside the mission limits, and whether another script changes its orientation afterward. Some assets' visible and collision geometry disagree at unusual scales. Test them in Arma before release.

## See also

- [Simple Mass Attach Items](Simple-Mass-Attach-Items)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
