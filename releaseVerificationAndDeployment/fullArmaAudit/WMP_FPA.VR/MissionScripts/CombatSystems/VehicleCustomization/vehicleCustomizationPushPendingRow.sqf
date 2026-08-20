/*
 * Author: WaldoTheWarfighter
 * Appends one already-validated row to the ZEN "Vehicle Customisation - Editor" dialog's client-local
 * Pending Changes list, generating a stable UID and a human-readable label for it. Called only after
 * one of the four Waldo_fnc_VehCust_collect*Row functions has already returned a non-empty row -
 * this function does no validation of its own, it only stores and labels what it is given.
 *
 * Pending rows are stored as [_uid, _rowType, _rowData, _labelText] in
 * _disp setVariable ["WaldoVehCust_PendingRows", _rows] - the UID (not array index) is the stable
 * identity used by Waldo_fnc_VehCust_removePendingRow and the Pending Changes RscListbox's lbData,
 * matching MissionScripts/EconomySystems/Command/promptGroundCommand.sqf's lbData-keyed identity
 * pattern.
 *
 * Arguments:
 * 0: Display <DISPLAY> - the open Vehicle Customisation - Editor display (optional, default: displayNull)
 * 1: Row Type <STRING> - "TURRET", "PYLON", "APPEARANCE", or "COMPONENT" (optional, default: "")
 * 2: Row Data <ARRAY> - the row returned by the matching collector (optional, default: [])
 *
 * Return Value:
 * Nothing - mutates the display's WaldoVehCust_PendingRows variable. Does not refresh the visible
 * RscListbox; call Waldo_fnc_VehCust_refreshPendingList afterward.
 *
 * Example:
 * [_disp, "TURRET", _row] call Waldo_fnc_VehCust_pushPendingRow;
 * [_disp] call Waldo_fnc_VehCust_refreshPendingList;
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationPromptEditor.sqf
 * (every tab's Add button, and the Copy From Nearby Vehicle overlay's pick handler).
 */

params [["_disp", displayNull], ["_rowType", ""], ["_rowData", []]];
if (isNull _disp || {_rowType == ""} || {_rowData isEqualTo []}) exitWith {};

private _uid = format ["%1_%2", diag_tickTime, round (random 1e9)];

private _label = switch (_rowType) do {
    case "TURRET": {
        _rowData params [["_t", ""], ["_path", []], ["_pi", -1], ["_action", ""], ["_weapon", ""], ["_mag", ""], ["_cnt", 0], ["_qty", 1]];
        private _magPart = if (_mag != "") then {format [" [%1 x%2]", _mag, _qty]} else {""};
        format ["TURRET %1 - %2 %3%4", _path, _action, _weapon, _magPart]
    };
    case "PYLON": {
        _rowData params [["_t", ""], ["_path", []], ["_pi", -1], ["_action", ""], ["_weapon", ""], ["_mag", ""], ["_cnt", 0]];
        format ["PYLON %1 - %2 %3", _pi, _action, _mag]
    };
    case "APPEARANCE": {
        _rowData params [["_t", ""], ["_slot", -1], ["_action", ""], ["_val", ""]];
        private _valText = if (_val isEqualType []) then {"solid color"} else {_val};
        format ["APPEARANCE Slot %1 - %2 %3", _slot, _action, _valText]
    };
    case "COMPONENT": {
        _rowData params [["_sel", ""], ["_path", []], ["_hide", true]];
        private _actionText = if (_hide) then {"Remove"} else {"Restore"};
        private _pathText = if (count _path > 0) then {format [" (turret %1)", _path]} else {""};
        format ["COMPONENT %1 - %2%3", _sel, _actionText, _pathText]
    };
    default {"UNKNOWN ROW"};
};

private _rows = _disp getVariable ["WaldoVehCust_PendingRows", []];
_rows pushBack [_uid, _rowType, _rowData, _label];
_disp setVariable ["WaldoVehCust_PendingRows", _rows];
