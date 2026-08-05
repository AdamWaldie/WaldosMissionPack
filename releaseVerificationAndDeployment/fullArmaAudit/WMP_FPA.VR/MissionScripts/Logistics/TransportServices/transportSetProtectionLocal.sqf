/*
 * Author: WaldoTheWarfighter, Val
 * Makes a registered transport and only its original AI service crew invulnerable on whichever
 * machines currently own those objects. Passenger players are deliberately excluded.
 * Locality and authority: may be sent to every machine, but allowDamage is applied only to local
 * objects. The server monitor repeats this one-shot call after a vehicle or AI locality change.
 *
 * Arguments:
 * 0: registered transport <OBJECT>.
 *
 * Return Value: <BOOL> - true when the local protection pass completed.
 *
 * Example: [this] call Waldo_fnc_TransportSetProtectionLocal;
 * Current callers: Waldo_fnc_TransportRegister and locality-change handling in the server monitor.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle) exitWith {false};
if (local _vehicle) then {_vehicle setDamage 0; _vehicle allowDamage false};
{
    if (!isNull _x && {local _x}) then {_x setDamage 0; _x allowDamage false};
} forEach (_vehicle getVariable ["Waldo_TransportService_BaseCrew", []]);
true
