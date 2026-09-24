/*
 * Author: WaldoTheWarfighter
 * Purpose: Applies one server-authorised cargo or FFV seat lock on the vehicle owner.
 * Locality / Authority: Runs only where the vehicle is local; remote requests must come from the server.
 * Repeat / JIP: Repeated commands are harmless. The server reasserts desired locks after locality changes.
 * Arguments: vehicle <OBJECT>, kind <STRING> ("CARGO" or "TURRET"), key <NUMBER or ARRAY>, lock <BOOL>.
 * Return Value: <BOOL> whether the local engine command was applied.
 * Current caller: Waldo_fnc_PhysicalCargoSeatsServer via server remote execution.
 * Example: [truck, "TURRET", [1], true] remoteExecCall ["Waldo_fnc_PhysicalCargoSeatLockLocal", truck];
 */
params [["_vehicle", objNull, [objNull]], ["_kind", "", [""]],
    ["_key", -1, [-1, []]], ["_lock", false, [false]]];
if (isNull _vehicle || {!local _vehicle}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {false};
if (_kind isEqualTo "CARGO" && {!(_key isEqualType 0 && {_key >= 0})}) exitWith {false};
if (_kind isEqualTo "TURRET" && {!(_key isEqualType [] && {_key isNotEqualTo []})}) exitWith {false};
if !(_kind in ["CARGO", "TURRET"]) exitWith {false};
switch (_kind) do {
    case "CARGO": {
        _vehicle lockCargo [_key, _lock];
    };
    case "TURRET": {
        _vehicle lockTurret [_key, _lock];
    };
};
diag_log format ["[WMP PHYSICAL CARGO SEATS] owner command vehicle=%1 kind=%2 key=%3 lock=%4 result=%5 owner=%6",
    typeOf _vehicle, _kind, _key, _lock,
    if (_kind isEqualTo "CARGO") then {_vehicle lockedCargo _key} else {_vehicle lockedTurret _key},
    clientOwner];
true
