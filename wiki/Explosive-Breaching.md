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

`deleteOriginal = false` is the recoverable choice. Deleting an object makes reset impossible. Replacement pieces are advanced and require in-engine collision testing. See [Optional Feature Systems](Optional-Feature-Systems#explosive-wall-breaching) for the full profile and replacement format.

## If the wall does not open

Check ACE Explosives, the enable row, the wall's exact class, the charge's CfgAmmo class, its distance and the profile's required strength. `Waldo_fnc_BreachingStop` stops further processing. Breaching has no dedicated ZEN module.

## See also

- [Construction Objects](Construction-Objects)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
