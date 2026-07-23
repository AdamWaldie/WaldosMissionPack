/*
 * Author: Waldo
 * Turns any object into a defusable bomb: a ready-made example of the generic mini game
 * interaction hook (Waldo_fnc_MiniGameInteraction). Adds a "Defuse Bomb" interaction that
 * opens the wire-cut challenge; passing it disarms the device, failing it (wrong wire, timeout
 * or abort) detonates it. All outcomes are applied on the server.
 *
 * Call from the object's Eden "Initialization" field so it runs on every machine.
 *
 * Arguments:
 * _object  - Object - the device
 * _options - Array  - array of [key, value] pairs, all optional:
 *              "title"             String - action text (default "Defuse Bomb")
 *              "wireCount"         Number - wires shown, 3..6 (default 5)
 *              "timeLimit"         Number - seconds on the clock, 0 = none (default 20)
 *              "detonateOnFailure" Bool   - explode on failure (default true)
 *              "explosive"         String - ammo/magazine class spawned to detonate
 *                                            (default "IEDLandBig_Remote_Ammo")
 *              "defusedVariable"   String - object var set true on success (default "Waldo_MG_BombDefused")
 *              "oneShot"           Bool   - single attempt (default true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [this] call Waldo_fnc_BombDefuseSetup;
 * [this, [["wireCount", 6], ["timeLimit", 15]]] call Waldo_fnc_BombDefuseSetup;
 */

params [
    ["_object", objNull, [objNull]],
    ["_options", [], [[]]]
];

if (isNull _object) exitWith {};

private _opt = {
    params ["_k", "_def"];
    private _r = _def;
    { if ((_x select 0) == _k) exitWith { _r = _x select 1; }; } forEach _options;
    _r
};

private _title = ["title", "Defuse Bomb"] call _opt;
private _wireCount = ["wireCount", 5] call _opt;
private _timeLimit = ["timeLimit", 20] call _opt;
private _detonate = ["detonateOnFailure", true] call _opt;
private _explosive = ["explosive", "IEDLandBig_Remote_Ammo"] call _opt;
private _defusedVar = ["defusedVariable", "Waldo_MG_BombDefused"] call _opt;
private _oneShot = ["oneShot", true] call _opt;

// Detonation parameters live on the object so the (asynchronous, server-side) callbacks can
// read them without capturing this scope.
_object setVariable ["Waldo_MG_Bomb_Detonate", _detonate, true];
_object setVariable ["Waldo_MG_Bomb_Explosive", _explosive, true];
_object setVariable ["Waldo_MG_Bomb_DefusedVar", _defusedVar, true];

private _onSuccess = {
    params ["_obj", "_actor"];
    private _var = _obj getVariable ["Waldo_MG_Bomb_DefusedVar", "Waldo_MG_BombDefused"];
    _obj setVariable [_var, true, true];
    _obj setVariable ["Waldo_MG_BombDefused", true, true];
    [format ["%1 defused the device.", name _actor]] remoteExec ["systemChat", 0];
};

private _onFailure = {
    params ["_obj", "_actor"];
    [format ["%1 failed the defusal procedure.", name _actor]] remoteExec ["systemChat", 0];
    if (_obj getVariable ["Waldo_MG_Bomb_Detonate", true]) then {
        private _mag = _obj getVariable ["Waldo_MG_Bomb_Explosive", "IEDLandBig_Remote_Ammo"];
        private _pos = getPosATL _obj;
        deleteVehicle _obj;
        private _boom = createVehicle [_mag, _pos, [], 0, "CAN_COLLIDE"];
        _boom setPosATL _pos;
    };
};

[
    _object,
    "wirecut",
    [_wireCount, _timeLimit, _title],
    _onSuccess,
    _onFailure,
    [
        ["title", _title],
        ["oneShot", _oneShot],
        ["icon", "\a3\ui_f\data\igui\cfg\actions\take_ca.paa"]
    ]
] call Waldo_fnc_MiniGameInteraction;
