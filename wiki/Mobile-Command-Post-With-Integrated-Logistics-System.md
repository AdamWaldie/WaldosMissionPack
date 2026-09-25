# Mobile Command Post

> **Use this page when:** you want players to deploy an MHQ as a field respawn point, with an optional Quartermaster on the same object.

An MHQ can be a vehicle or a static object. Players use **Set Up Command Post** to create its respawn point and map marker, then **Tear Down Command Post** before moving it. You can also make the deployed MHQ issue supplies through the [Quartermaster](Quartermaster).

## Before you start

- Copy the complete WMP pack into your mission and keep its init files. [Quickstart](Quickstart-Guide) covers the first installation.
- ACE Interact provides the command-post menu. If ACE Interact is unavailable, WMP adds ordinary Arma actions instead.
- The MHQ itself needs no feature switch. To add Quartermaster issues, leave `Waldo_Quartermaster_Enable` on in `MissionConfig/logisticsConfig.sqf`.
- Run the setup call from the MHQ's Eden **Init** field. WMP keeps deployment state on the server and installs interactions for current players and players who join later.

## Set up an MHQ in Eden

1. Place the vehicle or static object that players will operate.
2. Place a **Game Logic** near it. Synchronise the Game Logic **to the MHQ**.
3. Place any scenery that should appear when the MHQ deploys. Synchronise each of those objects **to the Game Logic**. Leave a clear spot beside the MHQ for respawning players.
4. Put this in the MHQ object's **Init** field:

   ```sqf
   [this] call Waldo_fnc_MHQSetup;
   ```

5. Preview the mission in multiplayer. Deploy and tear down the MHQ, then check the marker, respawn point and scenery.

WMP attaches the synchronised scenery to a vehicle MHQ while it moves. If that vehicle settles lower when simulation starts, adjust the scenery's Eden height and test again. Synchronise the Game Logic directly to the MHQ so WMP does not have to search for a nearby logic object.

## Add Quartermaster issues

Pass `true` as the third argument. This example uses modern construction audio and places issued objects four metres behind the MHQ:

```sqf
[this, true, true, 180, 4] call Waldo_fnc_MHQSetup;
```

The Quartermaster becomes available when players deploy the MHQ. Tearing it down hides the issue actions again. All ten issue types are on by default. Change their availability, quantities and crate classes in `MissionConfig/logisticsConfig.sqf`.

| Setting | Shipped value | Change it when |
|---|---:|---|
| `Waldo_QM_Ammo_CrateClass` | `B_supplyCrate_F` | You want a different Ammo Box model. |
| `Waldo_QM_Supply_CrateClass` | `B_supplyCrate_F` | You want a different Heavy Supply Box model. |
| `Waldo_QM_Medical_CrateClass` | Empty | You want to override the ACE-aware medical crate choice. |
| `Waldo_QM_Grenades_CrateClass` | `Box_NATO_Ammo_F` | You want a different Grenades Box model. |
| `Waldo_QM_Explosives_CrateClass` | `Box_NATO_AmmoOrd_F` | You want a different Explosives Box model. |
| `Waldo_QM_Rearm_CrateClass` | `Box_NATO_AmmoVeh_F` | You want a different Rearm Box model. |

Open `MissionConfig/logisticsConfig.sqf`, find the setting name, and replace only its class string with a valid `CfgVehicles` class. You do not need to paste these settings into `initServer.sqf`. See [Quartermaster crate choices](Quartermaster#change-crate-models-and-quantities) for the general spawner defaults and ACE rearm limits.

## Script call

`[target, construction audio, quartermaster, issue direction, issue distance] call Waldo_fnc_MHQSetup;`

| Position | Type | Default | Meaning |
|---|---|---|---|
| 0 | Object | Required | The MHQ object. Use `this` in its own Init field. |
| 1 | Boolean | `false` | Use modern construction audio when `true`; use wooden construction sounds when `false`. |
| 2 | Boolean | `false` | Add a deployment-controlled Quartermaster when `true`. |
| 3 | Number | `180` | Issue bearing relative to the MHQ: `0` front, `90` right, `180` rear, `270` left. |
| 4 | Number | `4` | Starting issue distance in metres. |

The call returns `true` when WMP accepts a non-null MHQ object, or `false` for a missing object. Eden Init fields, compositions and mission scripts call it. The server owns the deployment, marker and respawn state; each client owns its local menu. Calling setup again on the same object does not add another set of actions.

## During play and troubleshooting

- **No command-post action:** Check that you put the call on the MHQ object and that it exists when the mission starts. Stop the vehicle before trying to deploy.
- **Scenery does not follow the MHQ:** Check both links: MHQ to Game Logic, then scenery to Game Logic.
- **No supply choices:** Check the third argument, `Waldo_Quartermaster_Enable`, and whether the MHQ is deployed.
- **Respawn point or marker remains:** Use **Tear Down Command Post**. WMP removes the deployment marker and respawn position when it tears down the MHQ.

## See also

- [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster)
- [ACE Cargo and Object Handling](ACE-Cargo-And-Object-Handling)
- [Eden Compositions](Eden-Compositions)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
