/*
 * Author: WaldoTheWarfighter, Val
 * Clears a completed WMP transport route and leaves its AI service vehicle stopped at the physical
 * pickup, destination or base position. Helicopters receive the ordinary engine LAND command and
 * are allowed to idle down naturally; this function does not manipulate engine state, repeatedly
 * force LAND, disable AI features or run a background grounded-hold worker.
 *
 * Locality and authority: called by the authoritative server after a validated arrival, then routed
 * to the machine currently owning the AI group. It changes only local group/vehicle movement state.
 * Repeated calls are safe. A later dispatch releases doStop with doFollow before creating its route.
 * No JIP state is required because the server registry remains authoritative for service state.
 *
 * Arguments:
 * 0: service group <GROUP>
 * 1: stop position ATL <ARRAY> (informational; default [])
 * 2: service vehicle <OBJECT> (default objNull)
 *
 * Return Value: Boolean - true when applied locally or forwarded to the current group owner.
 * Current caller: Waldo_fnc_TransportReportServer after pickup, destination and physical RTB.
 * Example: [_group, getPosATL _helicopter, _helicopter] call Waldo_fnc_TransportStopGroupLocal;
 */

params [
    ["_group", grpNull, [grpNull]],
    ["_position", [], [[]]],
    ["_vehicle", objNull, [objNull]]
];
if (isNull _group) exitWith {false};
if (!local _group) exitWith {
    [_group, _position, _vehicle] remoteExecCall ["Waldo_fnc_TransportStopGroupLocal", groupOwner _group];
    true
};

for "_index" from ((count waypoints _group) - 1) to 0 step -1 do {
    deleteWaypoint [_group, _index];
};
doStop leader _group;

if (!isNull _vehicle && {_vehicle isKindOf "Helicopter"}) then {
    if (_vehicle getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]) then {
        // Touchdown is already complete. Preserve LAND while removing only the vector controller;
        // restoring transit height or LAND NONE here creates an unnecessary post-arrival lift.
        [_vehicle, true, "LAND"] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
    };
    _vehicle land "LAND";
};
true
