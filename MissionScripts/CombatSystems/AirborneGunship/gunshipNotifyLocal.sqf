/*
 * Author: Waldo
 * Shows an airborne-gunship status message through the pack notification presentation.
 * Arguments: 0: message <STRING>
 * Return Value: Boolean
 */

params [["_message", "", [""]]];
if !(hasInterface) exitWith {false};
["AIRBORNE GUNSHIP", _message, "INFO", "AIRBORNE_GUNSHIP"] call Waldo_fnc_FeatureNotifyLocal
