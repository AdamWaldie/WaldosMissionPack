/*
 * Author: Waldo
 * Opens a private one-click map designation for an assigned gunship controller.
 * Arguments: 0: id <STRING>
 * Return Value: Boolean
 */

params ["_id"];
if !(hasInterface) exitWith {false};
private _existing = missionNamespace getVariable ["Waldo_Gunship_MapClickEH", -1];
if (_existing >= 0) then {removeMissionEventHandler ["MapSingleClick", _existing]};
openMap [true, true];
["Select a new gunship orbit centre on the map."] call Waldo_fnc_GunshipNotifyLocal;
missionNamespace setVariable ["Waldo_Gunship_MapSelectionId", _id];
private _handler = addMissionEventHandler ["MapSingleClick", {
    params ["_units", "_position"];
    private _id = missionNamespace getVariable ["Waldo_Gunship_MapSelectionId", ""];
    if (_id == "") exitWith {};
    [_id, "SET_ORBIT", [_position], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2];
    openMap [false, false];
    private _handler = missionNamespace getVariable ["Waldo_Gunship_MapClickEH", -1];
    if (_handler >= 0) then {removeMissionEventHandler ["MapSingleClick", _handler]};
    missionNamespace setVariable ["Waldo_Gunship_MapClickEH", -1];
    missionNamespace setVariable ["Waldo_Gunship_MapSelectionId", ""];
}];
missionNamespace setVariable ["Waldo_Gunship_MapClickEH", _handler];
true
