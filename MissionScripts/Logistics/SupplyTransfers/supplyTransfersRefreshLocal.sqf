/*
 * Author: WaldoTheWarfighter
 * Purpose: Refreshes grouped available rows and the review queue after explicit panel changes.
 * Locality / Authority: Interface-local, read-only inventory presentation.
 * Repeat / JIP: Safe to repeat; rebuilding list rows does not mutate cargo or create workers.
 * Arguments: transfer display <DISPLAY>. Return Value: <BOOL> refreshed.
 * Current callers: panel open, queue buttons and server-result callback.
 * Example: [_display] call Waldo_fnc_SupplyTransfersRefreshLocal;
 * Result: The open panel reflects current inventory, destination and queued transfer rows.
 */
params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {false};
private _source = _display getVariable ["Waldo_SupplyTransfers_Source", objNull];
private _destinations = _display getVariable ["Waldo_SupplyTransfers_Destinations", []];
private _combo = _display getVariable ["Waldo_SupplyTransfers_DestinationCombo", controlNull];
private _list = _display getVariable ["Waldo_SupplyTransfers_Items", controlNull];
if (isNull _source || {isNull _combo} || {isNull _list}) exitWith {false};
private _destinationIndex = lbCurSel _combo;
private _destination = if (_destinationIndex >= 0) then {_destinations param [_destinationIndex, objNull]} else {objNull};
private _previousRow = lbCurSel _list;
_display setVariable ["Waldo_SupplyTransfers_Destination", _destination];
lbClear _list;
private _rows = [];
if (!isNull _source) then {
    private _snapshot = [_source] call Waldo_fnc_SupplyTransfersSnapshot;
    if (_snapshot isNotEqualTo []) then {
        {
            private _category = ["ITEM", "WEAPON", "MAGAZINE", "BACKPACK"] select _forEachIndex;
            {
                private _row = _x;
                private _class = _row select 0;
                private _config = switch (_category) do {
                    case "BACKPACK": {configFile >> "CfgVehicles" >> _class};
                    case "MAGAZINE": {configFile >> "CfgMagazines" >> _class};
                    default {configFile >> "CfgWeapons" >> _class};
                };
                private _name = getText (_config >> "displayName");
                if (_name isEqualTo "") then {_name = _class};
                private _available = if (_category == "ITEM") then {_row select 1} else {1};
                private _detail = switch (_category) do {
                    case "MAGAZINE": {format ["%1 rounds", _row select 1]};
                    case "BACKPACK": {"contents retained"};
                    case "WEAPON": {"attachments retained"};
                    default {""};
                };
                private _existing = _rows findIf {(_x select 0) isEqualTo _category && {(_x select 1) isEqualTo _row}};
                if (_existing < 0) then {
                    _rows pushBack [_category, _row, _available, _name, _detail];
                } else {
                    private _entry = +(_rows select _existing);
                    _entry set [2, (_entry select 2) + _available];
                    _rows set [_existing, _entry];
                };
            } forEach _x;
        } forEach _snapshot;
    };
};
_display setVariable ["Waldo_SupplyTransfers_Rows", _rows];
{
    _x params ["_category", "_row", "_available", "_name", "_detail"];
    _list lbAdd format ["%1  |  %2  |  %3 available%4", _category, _name, _available,
        if (_detail isEqualTo "") then {""} else {"  |  " + _detail}];
} forEach _rows;
if (_rows isNotEqualTo []) then {_list lbSetCurSel ((_previousRow max 0) min (count _rows - 1))};
private _queueList = _display getVariable ["Waldo_SupplyTransfers_QueueList", controlNull];
if (!isNull _queueList) then {
    lbClear _queueList;
    {
        _x params ["_category", "_row", "_quantity", "_name", "_detail"];
        _queueList lbAdd format ["%1 x %2  |  %3%4", _quantity, _name, _category,
            if (_detail isEqualTo "") then {""} else {"  |  " + _detail}];
    } forEach (_display getVariable ["Waldo_SupplyTransfers_Queue", []]);
};
private _capacity = _display getVariable ["Waldo_SupplyTransfers_Capacity", controlNull];
if (!isNull _capacity && {!isNull _destination}) then {
    _capacity ctrlSetText format ["SOURCE %1 / %2     DESTINATION %3 / %4     RANGE %5 m",
        round loadAbs _source, round maxLoad _source, round loadAbs _destination,
        round maxLoad _destination, round ((missionNamespace getVariable ["Waldo_SupplyTransfers_Range", 20]) max 2 min 50)];
};
true
