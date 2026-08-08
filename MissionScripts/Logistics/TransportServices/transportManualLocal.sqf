/*
 * Author: WaldoTheWarfighter
 * Performs the actual seat swap and waypoint clearing for taking or releasing manual control of a
 * registered transport, on whichever machine currently owns its AI group. Never ejects a unit out of
 * the vehicle - the outgoing occupant is always reseated into a free cargo or turret position first;
 * callers are responsible for refusing the handoff when no free seat exists.
 * Locality and authority: runs only where the vehicle's driver's group is local; forwards itself
 * otherwise. Called only by Waldo_fnc_TransportTakeManualServer / Waldo_fnc_TransportReleaseManualServer.
 *
 * Arguments:
 * 0: mode <STRING> - TAKE or RELEASE.
 * 1: vehicle <OBJECT>.
 * 2: requester <OBJECT> (TAKE only) - the player taking control.
 * 3: AI pilot <OBJECT> (RELEASE only) - the original AI pilot to restore.
 * 4: config <HASHMAP> (RELEASE only) - the service's registered config, used to reapply standing AI
 *    orders (behaviour, speed mode, cruise altitude) once the AI pilot is back in the driver's seat.
 *
 * Return Value: Boolean - true on the owning machine.
 *
 * Example:
 * ["TAKE", _vehicle, _requester] call Waldo_fnc_TransportManualLocal;
 * ["RELEASE", _vehicle, objNull, _aiPilot, _config] call Waldo_fnc_TransportManualLocal;
 *
 * Current callers: Waldo_fnc_TransportTakeManualServer, Waldo_fnc_TransportReleaseManualServer.
 */
params [
    ["_mode", "", [""]], ["_vehicle", objNull, [objNull]],
    ["_requester", objNull, [objNull]], ["_aiPilot", objNull, [objNull]],
    ["_config", createHashMap, [createHashMap]]
];
if (isNull _vehicle || {isNull driver _vehicle}) exitWith {false};
private _group = group driver _vehicle;
if (!local _group) exitWith {
    [_mode, _vehicle, _requester, _aiPilot, _config] remoteExecCall ["Waldo_fnc_TransportManualLocal", groupOwner _group];
    true
};
for "_i" from ((count waypoints _group) - 1) to 0 step -1 do {deleteWaypoint [_group, _i]};
doStop leader _group;
if (_vehicle getVariable ["Waldo_ImprovedHelicopterLanding_Active", false]) then {
    [_vehicle, false, ""] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
};

private _moveOutgoingToFreeSeat = {
    params ["_unit"];
    if (isNull _unit) exitWith {};
    if ((_vehicle emptyPositions "cargo") > 0) exitWith {_unit moveInCargo _vehicle};
    private _freeTurrets = (allTurrets [_vehicle, true]) select {(_vehicle emptyPositions _x) > 0};
    if (count _freeTurrets > 0) then {_unit moveInTurret [_vehicle, _freeTurrets select 0]};
};

switch (toUpperANSI _mode) do {
    case "TAKE": {
        [driver _vehicle] call _moveOutgoingToFreeSeat;
        _requester moveInDriver _vehicle;
        _vehicle engineOn true;
    };
    case "RELEASE": {
        if (!isNull _aiPilot && {alive _aiPilot}) then {
            private _current = driver _vehicle;
            if (!isNull _current && {_current != _aiPilot}) then {[_current] call _moveOutgoingToFreeSeat};
            _aiPilot moveInDriver _vehicle;
            _group setBehaviourStrong (_config getOrDefault ["behaviour", "CARELESS"]);
            _group setCombatMode "BLUE";
            _group setSpeedMode (_config getOrDefault ["speedMode", "FULL"]);
            _vehicle engineOn true;
            if (_vehicle isKindOf "Helicopter") then {
                _vehicle land "NONE";
                // Array form forces strict AGL terrain-following - matches Waldo_fnc_TransportRegister.
                _vehicle flyInHeight [(_config getOrDefault ["cruiseAltitude", 80]) max 20, true];
            };
        };
    };
};
true
