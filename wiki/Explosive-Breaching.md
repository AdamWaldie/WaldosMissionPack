# Explosive Breaching

> **Use this page when:** an ACE demolition charge should open a specifically configured wall or object.

Breaching responds only to object classes listed in its profile. The shipped example targets the vanilla `Land_City2_8m_F` wall. Enabling the feature does not make every building destructible, and Arma cannot cut arbitrary new collision holes into a model.

## Try the shipped wall profile

1. Place `Land_City2_8m_F` in Eden.
2. In `MissionConfig/environmentConfig.sqf`, change the existing `Waldo_Breaching_Enable` row from `false` to `true`.
3. In play, place an ACE M112 demolition block or satchel within five metres and detonate it.

The server checks the explosion and processes each wall once. The shipped profile hides the original wall to clear the opening, but retains it so `Waldo_fnc_BreachingReset` can restore it. Successful breaches are silent by default. Set `Waldo_Breaching_ShowNotifications` to `true` if the player who placed the successful charge should receive a WMP card.

## Configure another target

Edit the existing `Waldo_Breaching_Profiles` HashMap in `MissionConfig/environmentConfig.sqf`. Copy the complete example entry, separate entries with a comma, and replace the object classname. Keep `replacements = []` until the simple breach works. Each profile sets charge distance, accepted **CfgAmmo** classes, required strength, and whether to damage, hide or delete the original. Use `DemoCharge_Remote_Ammo`, not the inventory magazine classname. The shipped strength map gives a demo charge `1` and a satchel `3`.

The feature uses three existing config rows:

| Setting | Type | Shipped value | What it changes |
|---|---|---|---|
| `Waldo_Breaching_Enable` | Boolean | `false` | Installs the ACE explosion listener. |
| `Waldo_Breaching_ShowNotifications` | Boolean | `false` | Shows a WMP card to the successful charge's placer. |
| `Waldo_Breaching_Profiles` | HashMap | One `Land_City2_8m_F` entry | Exact target CfgVehicles class to the profile fields below. |
| `Waldo_Breaching_ExplosiveStrengths` | HashMap | Demo charge `1`, satchel `3` | CfgAmmo class to force from one detonation. |

Each entry in `Waldo_Breaching_Profiles` is a HashMap. Copy the shipped wall entry before changing a field:

| Profile key | Type | Shipped wall value | What it changes |
|---|---|---|---|
| `radius` | Number | `5` | Maximum detonation distance in metres. |
| `explosives` | Array of CfgAmmo classnames | Demo charge and satchel | Accepted detonation classes. |
| `requiredStrength` | Number | `1` | Force needed before the target opens. |
| `destroyOriginal` | Boolean | `true` | Damages the original. |
| `hideOriginal` | Boolean | `true` | Hides the original to clear the opening. |
| `deleteOriginal` | Boolean | `false` | Deletes the original permanently. Keep `false` if reset must work. |
| `replacements` | Array | `[]` | Optional debris or replacement pieces. |

Two demo charges satisfy `requiredStrength = 2`; one satchel with strength `3` also does. A replacement row has the form `["CfgVehicles_Classname", [leftRight, forwardBack, upDown], yaw, "CAN_COLLIDE", "ATL", scale]`. The last three values are optional and default to `"CAN_COLLIDE"`, `"ATL"` and `1`. Offsets are metres along the original wall's model axes. Replacement pieces are advanced and require in-engine collision testing. See [Optional Feature Systems](Optional-Feature-Systems#explosive-wall-breaching) for the lifecycle details.

## Script calls

The normal setup uses only the config rows and the player's ACE explosives. For a recoverable wall, run `[wall1, true] call Waldo_fnc_BreachingReset` on the server:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | Object | Required | The original wall object, which must still exist. |
| 1 | Boolean | `true` | Remove WMP-created replacement pieces as well as restoring the original. |

The server returns `true` when it accepts the reset, or `false` for a missing object or unauthorized request. Do not turn on `deleteOriginal` when you need this path. `[] call Waldo_fnc_BreachingStop` takes no arguments. It disables the server-owned feature and future breach processing, and removes runtime replay for joining players. Installed ACE event handlers remain harmless no-ops. It returns no useful value. Breaching has no dedicated ZEN module.

## If the wall does not open

Check ACE Explosives, the enable row, the wall's exact class, the charge's CfgAmmo class, its distance and the profile's required strength.

## See also

- [Construction Objects](Construction-Objects)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
