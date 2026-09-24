# Set Vehicle Upright

> **Use this page when:** players need to right a tipped land vehicle.

WMP adds **Set Vehicle Upright** to land vehicles automatically. No Eden Init line, ZEN module, or feature flag is required. This is a local action on the vehicle, separate from [Emergency Dismount](Optional-Feature-Systems#emergency-dismount). Emergency Dismount moves occupants out. This action rights the vehicle when a player chooses it.

## Use it in play

1. Get out of the vehicle and stand within six metres of it.
2. Wait until it is stationary. The action appears when Arma reports speed below 3 km/h and the vehicle tilts far enough to need righting.
3. Choose **Set Vehicle Upright** from the vehicle's action menu.

The server checks the player's request and sends the operation to the machine that owns the vehicle. WMP stops the vehicle, aligns it with the local terrain, and places it above the ground using its model bounds. Keep vehicle simulation enabled. Check the surroundings before use, especially on a slope or beside other vehicles. Arma reports a signed speed, so the action can appear while a vehicle reverses. Stop it before selecting the action.

This action does not repair damage or replace the [Vehicle Recovery](Vehicle-Recovery) workshop system.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
