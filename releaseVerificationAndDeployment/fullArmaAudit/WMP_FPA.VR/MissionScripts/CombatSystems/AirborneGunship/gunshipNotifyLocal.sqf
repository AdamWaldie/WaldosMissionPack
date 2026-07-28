/*
 * Author: Waldo
 * Shows an airborne-gunship status message through the pack notification presentation.
 * Arguments: 0: message <STRING>
 * Return Value: Boolean
 */

params [["_message", "", [""]]];
if !(hasInterface) exitWith {false};
if !(isNil "CBA_fnc_notify") then {
    [[], ["AIRBORNE GUNSHIP", 1.1, [0.45, 0.8, 1, 1]], [_message]] call CBA_fnc_notify;
} else {
    systemChat format ["[WMP] %1", _message];
};
true
