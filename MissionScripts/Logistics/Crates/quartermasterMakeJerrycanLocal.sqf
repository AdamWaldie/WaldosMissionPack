/*
 * Author: WaldoTheWarfighter
 * Purpose: Initialises an ACE jerrycan on every machine, including joiners.
 * Locality / Authority: Server-dispatched only; ACE requires this setup on clients and server.
 * Repeat / JIP: JIP-keyed dispatch; ACE setup is applied once per object per machine.
 * Arguments: can <OBJECT>, litres <NUMBER>. Return Value: <BOOL> applied.
 * Current caller: Waldo_fnc_QuartermasterExtendedSpawn.
 * Example: [can, 20] remoteExecCall ["Waldo_fnc_QuartermasterMakeJerrycanLocal", 0, can];
 * Result: ACE recognises the can as a fuel container with the requested litres.
 */
params [["_can", objNull, [objNull]], ["_litres", 20, [0]]];
if (isNull _can || {isNil "ace_refuel_fnc_makeJerryCan"}) exitWith {false};
if (!isServer && {(!isRemoteExecuted || {remoteExecutedOwner isNotEqualTo 2})}) exitWith {false};
if (_can getVariable ["Waldo_QM_JerrycanInitialisedLocal", false]) exitWith {true};
[_can, _litres] call ace_refuel_fnc_makeJerryCan;
_can setVariable ["Waldo_QM_JerrycanInitialisedLocal", true];
true
