/*
 * Author: WaldoTheWarfighter
 * Applies one completed service cycle on the aircraft's owning machine.
 * Arguments: 0: aircraft <OBJECT>; 1: config <HASHMAP>
 * Return Value: Boolean
 */

params ["_aircraft", "_config"];
if !(isServer && {!isNull _aircraft} && {alive _aircraft}) exitWith {false};
[_aircraft, ((_config getOrDefault ["serviceFuelFraction", 1]) max 0) min 1] remoteExecCall ["setFuel", owner _aircraft];
[_aircraft, ((_config getOrDefault ["serviceAmmoFraction", 1]) max 0) min 1] remoteExecCall ["setVehicleAmmo", owner _aircraft];
[_aircraft, ((_config getOrDefault ["serviceDamage", 0]) max 0) min 1] remoteExecCall ["setDamage", owner _aircraft];
true
