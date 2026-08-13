/*
 * Author: WaldoTheWarfighter
 * Beginner-friendly one-line way to give a gunship a standing controller (FAC/JTAC) from an object's
 * own Eden init field, instead of requiring a curator to run the "Gunship: Assign Controller" ZEN
 * module every mission start. A unit and its gunship are normally placed as two separate Eden
 * objects, and object init fields have no guaranteed order against each other - this waits (bounded)
 * for the named system to finish registering before assigning, so it works regardless of which
 * object's init field happens to run first.
 *
 * Server-only work: it silently no-ops (returns false) on every non-server machine, so it is safe to
 * call directly from an object's own Eden init field with no isServer wrapper - exactly like
 * Waldo_fnc_Jammer and Waldo_fnc_HazardRegisterPresetZone, the server's own execution of that same
 * init line is what actually assigns the controller.
 *
 * Arguments:
 * 0: unit <OBJECT> - the player/unit to assign as controller.
 * 1: id <STRING> - the Waldo_fnc_GunshipRegister system id to assign it to.
 * 2: timeout <NUMBER> - seconds to wait for that id to finish registering before giving up
 *    (optional, default 60 - registration is normally near-instant, but a heavy multi-feature
 *    mission's init.sqf, or a slow-spawning aircraft, can legitimately still be finishing).
 *
 * Return Value:
 * Boolean - true when accepted (the actual assignment happens a moment later once registration is
 * confirmed; check the RPT for "[WMP GUNSHIP]" lines naming that id if it never becomes the
 * controller). False immediately when the unit/id are invalid.
 *
 * Example:
 * // From a placed unit's own init field in Eden - no isServer wrapper needed:
 * [this, "EXAMPLE_GUNSHIP"] call Waldo_fnc_GunshipAssignControllerOnStart;
 *
 * Current callers: Gunship Support Example (Full) composition, mission-maker setup.
 */

params [
    ["_unit", objNull, [objNull]],
    ["_id", "", [""]],
    ["_timeout", 60, [0]]
];
if (isNull _unit || {_id == ""}) exitWith {false};
if !(isServer) exitWith {false};

[_unit, _id, _timeout] spawn {
    params ["_unit", "_id", "_timeout"];
    private _deadline = serverTime + _timeout;
    waitUntil {
        sleep 0.1;
        isNull _unit
        || {_id in keys (missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap])}
        || {serverTime >= _deadline}
    };
    if (isNull _unit) exitWith {};
    if !(_id in keys (missionNamespace getVariable ["Waldo_Gunship_Registry", createHashMap])) exitWith {
        diag_log format ["[WMP GUNSHIP] AssignControllerOnStart abandoned for id=%1: registration never completed within %2 seconds.", _id, _timeout];
    };
    [_id, "ASSIGN", [_unit], objNull] call Waldo_fnc_GunshipServerHandle;
};
true
