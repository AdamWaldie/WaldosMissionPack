/*
 * Author: WaldoTheWarfighter
 * Removes one row from the ZEN "Vehicle Customisation - Editor" dialog's client-local Pending Changes
 * list by its stable UID (never by array index - matching
 * MissionScripts/EconomySystems/Command/promptGroundCommand.sqf's lbData-keyed removal pattern).
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 * 1: Uid <STRING> - the pending row's UID, read from the Pending Changes RscListbox's lbData for the
 *    currently selected row (optional, default: "")
 *
 * Return Value:
 * Nothing - mutates the display's WaldoVehCust_PendingRows variable. Does not refresh the visible
 * RscListbox; call Waldo_fnc_VehCust_refreshPendingList afterward.
 *
 * Example:
 * private _uid = _list lbData (lbCurSel _list);
 * [_disp, _uid] call Waldo_fnc_VehCust_removePendingRow;
 * [_disp] call Waldo_fnc_VehCust_refreshPendingList;
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (Remove Selected Pending Row button).
 */

params [["_disp", displayNull], ["_uid", ""]];
if (isNull _disp || {_uid == ""}) exitWith {};

private _rows = _disp getVariable ["WaldoVehCust_PendingRows", []];
_rows = _rows select {(_x select 0) != _uid};
_disp setVariable ["WaldoVehCust_PendingRows", _rows];
