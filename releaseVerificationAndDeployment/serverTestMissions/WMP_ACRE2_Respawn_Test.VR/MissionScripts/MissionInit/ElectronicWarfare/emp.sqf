/*
 * Author: WaldoTheWarfighter
 * Detonates an electromagnetic pulse at a position: a one-shot area effect that fries electronics
 * for a while. Infantry in range lose their night-vision goggles and (TFAR) radio use; vehicles
 * have their engines killed; every affected player gets a white-out flash and a clear on-screen
 * message so it reads as an EW event, not a bug. Units and vehicles tagged with Waldo_fnc_EMPImmune
 * are spared, and occupants of an immune vehicle are spared too. Server-authoritative - calling on
 * a client forwards to the server. Because it fires once and reverts on a timer, it costs nothing
 * to leave available (no polling loops).
 *
 * Arguments:
 * 0: Position <ARRAY> - centre of the pulse (ASL/AGL world position)
 * 1: Radius <NUMBER> - effect radius in metres (optional, default: 150)
 * 2: Duration <NUMBER> - seconds the electronics stay down (optional, default: 30)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [getPosATL myObject, 200, 30] call Waldo_fnc_EMP;
 */

params [["_pos", [0, 0, 0]], ["_radius", 150], ["_duration", 30]];

if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_EMP", 2];
};

private _ents = _pos nearEntities [["Man", "Car", "Tank", "Air", "Ship", "Motorcycle", "StaticWeapon"], _radius];

{
    private _e = _x;
    private _immune = _e getVariable ["Waldo_EMP_Immune", false];
    // Infantry inside an immune vehicle are protected as well.
    if (!_immune && {_e isKindOf "Man"} && {!isNull objectParent _e}) then {
        if ((objectParent _e) getVariable ["Waldo_EMP_Immune", false]) then { _immune = true; };
    };
    if (!_immune) then {
        [_e, _duration] remoteExec ["Waldo_fnc_EMPApply", _e];
    };
} forEach _ents;

diag_log format ["[WMP EMP] EMP detonated at %1 (radius %2 m, %3 s) - %4 entities in range.", _pos, _radius, _duration, count _ents];
