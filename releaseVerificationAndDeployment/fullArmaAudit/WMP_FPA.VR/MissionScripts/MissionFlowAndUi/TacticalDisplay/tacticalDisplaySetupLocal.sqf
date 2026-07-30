/*
 * Author: WaldoTheWarfighter
 * Installs the repeat-safe local access action on one registered Tactical Display object.
 *
 * The action is local because `addAction` entries and player visibility checks belong to each
 * interface. It appears only within the configured access distance and with a clear VIEW-geometry
 * line from the player's eyes to the object. Both the player and target object are supplied to
 * `checkVisibility` as ignored endpoints so their own geometry does not block the test. Server
 * registration publishes this function with an object-keyed JIP identifier.
 *
 * Arguments:
 * 0: display object <OBJECT> - registered whiteboard, map board or suitable terminal.
 *
 * Return Value:
 * Boolean - true when the action is installed; false for invalid, duplicate or non-interface calls.
 *
 * Example:
 * [_board] call Waldo_fnc_TacticalDisplaySetupLocal;
 *
 * Current caller: TacticalDisplayRegister through an object-keyed JIP remote call.
 */

params [["_object", objNull, [objNull]]];
if !(hasInterface) exitWith {false};
if (isNull _object || {_object getVariable ["Waldo_TacticalDisplay_LocalAction", -1] >= 0}) exitWith {false};
private _action = _object addAction [
    "Access Tactical Display",
    {params ["_target"]; [_target] call Waldo_fnc_TacticalDisplayOpenLocal},
    [], 1.5, true, true, "",
    "_target getVariable ['Waldo_TacticalDisplay_Registered', false] && {_target getVariable ['Waldo_TacticalDisplay_Unlocked', true]} && {_this distance _target <= (missionNamespace getVariable ['Waldo_TacticalDisplay_AccessDistance', 4])} && {[player, 'VIEW', _target] checkVisibility [eyePos player, aimPos _target] > 0.2}",
    5
];
_object setVariable ["Waldo_TacticalDisplay_LocalAction", _action];
true
