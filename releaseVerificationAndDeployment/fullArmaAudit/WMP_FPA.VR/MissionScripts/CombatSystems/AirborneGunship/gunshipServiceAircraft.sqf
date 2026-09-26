/*
 * Author: WaldoTheWarfighter
 * Applies one completed service cycle on the aircraft's owning machine.
 * Locality and authority: Server checks the live aircraft, then issues fuel, ammo
 * and damage commands to its current owner.
 * Repeat/JIP: Each call reapplies the configured service fractions. Aircraft engine state
 * replicates normally; a service request is not JIP replayed.
 * Arguments: 0: aircraft <OBJECT>; 1: config <HASHMAP>
 * Return Value: Boolean
 * Current caller: Waldo_fnc_GunshipMonitor at service completion.
 * Example: [_aircraft, _config] call Waldo_fnc_GunshipServiceAircraft;
 * Result: The aircraft's fuel, ammunition and damage are set to service targets on its owner.
 */

params ["_aircraft", "_config"];
if !(isServer && {!isNull _aircraft} && {alive _aircraft}) exitWith {false};
[_aircraft, ((_config getOrDefault ["serviceFuelFraction", 1]) max 0) min 1] remoteExecCall ["setFuel", owner _aircraft];
[_aircraft, ((_config getOrDefault ["serviceAmmoFraction", 1]) max 0) min 1] remoteExecCall ["setVehicleAmmo", owner _aircraft];
[_aircraft, ((_config getOrDefault ["serviceDamage", 0]) max 0) min 1] remoteExecCall ["setDamage", owner _aircraft];
true
