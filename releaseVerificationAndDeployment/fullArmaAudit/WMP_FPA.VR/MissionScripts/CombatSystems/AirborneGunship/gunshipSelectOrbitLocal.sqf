/*
 * Author: WaldoTheWarfighter
 * Starts a private one-click map designation for an assigned gunship controller.
 *
 * Locality and authority: runs only on the controller's interface client. It removes any previous
 * WMP gunship map-click handler before installing a replacement. If the normal player map is
 * already open, it is left open before and after selection; otherwise WMP opens it and closes it
 * after the click. The selected position is sent to the server, which validates controller access
 * and updates authoritative/JIP gunship state.
 *
 * Arguments:
 * 0: gunship system id <STRING> - registered Waldo_Gunship_PublicSystems key.
 *
 * Return Value:
 * Boolean - true when the local selection handler was installed; false without an interface or id.
 *
 * Current callers: assigned-controller ACE/vanilla actions created by
 * Waldo_fnc_GunshipSetupLocal.
 *
 * Example:
 * ["EXAMPLE_GUNSHIP"] call Waldo_fnc_GunshipSelectOrbitLocal;
 * Result: the next valid map click is sent to the server as this gunship's requested orbit centre.
 */

params [["_id", "", [""]]];
if !(hasInterface) exitWith {false};
if (_id == "") exitWith {false};
private _existing = missionNamespace getVariable ["Waldo_Gunship_MapClickEH", -1];
if (_existing >= 0) then {removeMissionEventHandler ["MapSingleClick", _existing]};
missionNamespace setVariable ["Waldo_Gunship_MapSelectionId", _id];
missionNamespace setVariable ["Waldo_Gunship_MapWasOpen", visibleMap];
private _handler = addMissionEventHandler ["MapSingleClick", {
    params ["_units", "_position"];
    private _id = missionNamespace getVariable ["Waldo_Gunship_MapSelectionId", ""];
    if (_id == "") exitWith {};
    [_id, "SET_ORBIT", [_position], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2];
    if !(missionNamespace getVariable ["Waldo_Gunship_MapWasOpen", false]) then {openMap [false, false]};
    private _handler = missionNamespace getVariable ["Waldo_Gunship_MapClickEH", -1];
    if (_handler >= 0) then {removeMissionEventHandler ["MapSingleClick", _handler]};
    missionNamespace setVariable ["Waldo_Gunship_MapClickEH", -1];
    missionNamespace setVariable ["Waldo_Gunship_MapSelectionId", ""];
    missionNamespace setVariable ["Waldo_Gunship_MapWasOpen", false];
}];
missionNamespace setVariable ["Waldo_Gunship_MapClickEH", _handler];
// Install the click handler first. When this action is invoked from an already-open map, calling
// openMap again can rebuild the display and consume or displace the newly installed interaction.
if !(visibleMap) then {openMap [true, true]};
["Select a new gunship orbit centre on the map."] call Waldo_fnc_GunshipNotifyLocal;
true
