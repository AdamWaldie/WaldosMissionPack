# Zeus Enhanced modules — registration overview

Requires Zeus Enhanced (`zen_main`); silently does nothing without it.

```sqf
[] call Waldo_fnc_ZenInitModules; // already called for interface clients in initPlayerLocal.sqf
```

Registers the **"Waldos Mission Modules"** category. This overview file
lists what's registered and which reference file covers configuring the
underlying feature — use it to route a "what Zeus modules does WMP add"
question, not as the primary config doc for any one feature.

| Zeus module | Calls | Detail in |
|---|---|---|
| Player Supply Crate | `Waldo_fnc_ZenSupplySpawner` | `loadout-logistics.md` |
| Field Hospital Crate | `Waldo_fnc_ZenMedicalSpawner` | `loadout-logistics.md` |
| Call Endex | `remoteExec ["Waldo_fnc_ENDEX", 0, true]` | `endex-aar.md` |
| Custom Mission End | `["end1"] remoteExec ["BIS_fnc_endMission", 0, true]` | `endex-aar.md` |
| Fortify Budget Manager | `Waldo_fnc_FortifyBudgetModule` | ACE fortify budget, see CLAUDE.md ACE3 section |
| Spawn AI Convoy | `Waldo_fnc_ZenConvoyModule` → `Waldo_fnc_SimpleAiConvoy` | turns nearest crewed land-vehicle group into a managed convoy |
| Loadout Save Point | `Waldo_fnc_ZenLoadoutSaveModule` | `respawn.md` |
| Safestart - Activate | `[true] remoteExec ["Waldo_fnc_SafeStart", 2]` | `safestart.md` |
| Safestart - Go Live (Lift) | `[false] remoteExec ["Waldo_fnc_SafeStart", 2]` | `safestart.md` |
| Safestart - Start Go-Live Countdown | `Waldo_fnc_ZenSafeStartTimer` | `safestart.md` |
| Radio Jammer - Place | `Waldo_fnc_ZenJammerPlace` | `jamming.md` |
| Radio Jammer - Toggle Nearest | `Waldo_fnc_ZenJammerToggle` | `jamming.md` |
| Radio Jammer - Remove Nearest | `Waldo_fnc_ZenJammerRemove` | `jamming.md` |
| EMP Detonation | `Waldo_fnc_ZenEMP` | `emp.md` |
| Plant Signal Tracker | `Waldo_fnc_ZenTracker` | `trackers.md` |
| Mission Flow: Send Notification | `Waldo_fnc_ZenNotify` → `Waldo_fnc_ZenNotifyServer` → `Waldo_fnc_NotificationBroadcast` | `ui-notifications.md` |

Waldos Economy Systems registers its own separate, larger set of Zeus
modules (15 core + 19 Economy) under its own Zeus category — labelled
**"WMP Economy Systems"** in the module browser (renamed from the older
"Waldos Economy Systems" category label; the *feature/system* is still
called Waldos Economy Systems everywhere else) — see `economy/README.md`,
not this file.

## Other WMP Zeus categories (not "Waldos Mission Modules")

Newer features register under their own domain-named Zeus categories rather
than the original "Waldos Mission Modules" catch-all. This overview file
doesn't re-list every one of them — route to the feature's own reference
file, which names its exact module(s):

| Category (approximate) | Feature | Reference |
|---|---|---|
| WMP Combat Systems | Dynamic AA - Create/Remove Nearest | `dynamic-aa.md` |
| WMP Combat Systems | Dynamic AO - Create/Remove | `dynamic-ao.md` |
| WMP Combat Systems | Gunship - Register/Assign/Set Orbit/Operational Control | `gunship.md` |
| WMP AI & Combat | Vehicle Weapon Loadout - Configure | `vehicle-weapon-loadout.md` |
| WMP Combat Systems / Air Operations | Paradrop - Create Drop Zone/Embark Players/Remove Operation | `paradrop.md` |
| WMP Logistics | Vehicle Recovery - Register Workshop/Vehicle/Carrier | `vehicle-recovery-rallies.md` |
| WMP Logistics | Field Resupply hub/carrier modules | `field-resupply.md` |
| WMP Transport | Transport Service - Register / Return to Base | `transport-services.md` |
| WMP Mission Flow / Respawn | Squad Rally Control | `vehicle-recovery-rallies.md` |
| — | Persistence - Control/Register Object/Save Now | `persistence.md` |
| — | Hazard - Create/Remove Nearest | `hazardous-environments.md` |
| — | Scale Object | `object-scaling.md` |
| — | Tactical Display registration | `tactical-display.md` |
| — | UI QA - Set Visual Theme | `ui-themes.md` |

## Static vs runtime verification

A repo-side static parity checker (`zeus_script_parity_checker.py`, in the
WMP dev repo only) verifies registration wiring exists — it does not prove
in-engine usability. If a user reports a Zeus module "not working" despite
correct registration, the next step is checking runtime placement/locality
in an actual Zeus session, not re-reading this file.
