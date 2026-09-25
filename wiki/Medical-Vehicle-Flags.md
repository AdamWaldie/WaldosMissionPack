# Medical Vehicle Flags

> **Use this page when:** you need to know which vehicles WMP marks as ACE medical vehicles.

WMP automatically sets `ace_medical_isMedicalVehicle` on selected medical variants. ACE Medical decides what that flag changes in play. This flag is independent of vehicle exit actions, paradrops, and Base Services healing.

## Check or set the flag

The shipped class list below is applied automatically during vehicle setup. For another
medical vehicle, put the example call in that vehicle's Eden Init field. There is no
WMP registration call or map marker for this flag.

| Input | Type | Value in the example |
| --- | --- | --- |
| `this` | Object | The vehicle placed in Eden. |
| `ace_medical_isMedicalVehicle` | Object-variable name String | The ACE flag read by ACE Medical. |
| Flag value | Boolean; ACE/WMP class default otherwise | `true` marks this vehicle as medical. |
| Public broadcast | Boolean | `true` in `setVariable` publishes the value to connected and later-joining clients. |

`setVariable` is an Arma command and does not return a WMP result. If several scripts
set the same flag, inspect the vehicle's final value in play.

| Vehicle | WMP detection |
|---|---|
| RHS UH-60 MEV | `RHS_UH60M_MEV2_d`, `RHS_UH60M_MEV_d`, `RHS_UH60M_MEV2`, `RHS_UH60M_MEV` |
| RHS M1230a1 | `rhsusf_M1230a1_usarmy_wd`, `rhsusf_M1230a1_usarmy_d` |

The existing vehicle setup also accepts an exact classname of `MED` in its UH-60, MRAP, truck, and Stryker branches. It does not automatically mark every class inheriting from those families. If your chosen mod vehicle is not one of the listed classes, set the ACE flag on that vehicle explicitly in Eden:

```sqf
this setVariable ["ace_medical_isMedicalVehicle", true, true];
```

Check the ACE Medical settings for your mission before relying on medical-vehicle treatment bonuses.

## If a vehicle is not recognised

Compare its exact `CfgVehicles` classname with the table. A similar-looking variant from another mod does not inherit WMP's explicit detection. For that variant, use the Eden Init example above and confirm ACE Medical's own vehicle settings are enabled.

## See also

- [Base Services](Base-Services)
- [Vehicle Recovery](Vehicle-Recovery)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
