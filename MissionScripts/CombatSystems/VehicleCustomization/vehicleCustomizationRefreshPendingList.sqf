/*
 * Author: WaldoTheWarfighter
 * Redraws the ZEN "Vehicle Customisation - Editor" dialog's permanent Pending Changes RscListbox from
 * the display's current WaldoVehCust_PendingRows state - the single place that list is ever rebuilt,
 * called after every push/remove/clear so the visible list never drifts from the underlying array.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_VehCust_refreshPendingList;
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (every Add button, Remove Selected, Clear All Pending, Apply All Pending, and the Copy From Nearby
 * Vehicle overlay's pick handler).
 */

params [["_disp", displayNull]];
if (isNull _disp) exitWith {};

private _list = _disp getVariable ["WaldoVehCust_PendingList", controlNull];
if (isNull _list) exitWith {};

private _rows = _disp getVariable ["WaldoVehCust_PendingRows", []];
lbClear _list;
{
    _x params [["_uid", ""], ["_rowType", ""], ["_rowData", []], ["_label", ""]];
    private _index = _list lbAdd _label;
    _list lbSetData [_index, _uid];
} forEach _rows;
