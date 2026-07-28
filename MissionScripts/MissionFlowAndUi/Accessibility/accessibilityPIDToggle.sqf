/*
 * Author: Waldo
 * Toggles the local friendly identification overlay without changing mission configuration.
 *
 * Arguments:
 * 0: state <BOOLEAN> - optional explicit state; omitted toggles current state
 *
 * Return Value:
 * Boolean - resulting visibility state
 *
 * Example:
 * [true] call Waldo_fnc_AccessibilityPIDToggle;
 */

if !(hasInterface) exitWith {false};
if (remoteExecutedOwner > 0) exitWith {false};
private _state = if (count _this > 0) then {_this select 0} else {
    !(missionNamespace getVariable ["Waldo_AccessibilityPID_Visible", false])
};
if !(_state isEqualType true) exitWith {false};
missionNamespace setVariable ["Waldo_AccessibilityPID_Visible", _state];
systemChat format ["[WMP] Friendly identification aid %1.", ["disabled", "enabled"] select _state];
_state
