/*
 * Author: WaldoTheWarfighter
 * Purpose: Builds a reviewed multi-line supply move and sends it as one server transaction.
 * Locality / Authority: Interface-local queue and input validation; server revalidates every line.
 * Repeat / JIP: Queue belongs to one modal and source; repeated sends are blocked until response.
 * Arguments: transfer display <DISPLAY>, mode <STRING> ADD|ADD_ALL|REMOVE|CLEAR|SEND (SEND).
 * Return Value: <BOOL> action accepted. Current caller: transfer-panel buttons.
 * Example: [_display, "ADD_ALL"] call Waldo_fnc_SupplyTransfersSubmitLocal;
 */
params [["_display", displayNull, [displayNull]], ["_mode", "SEND", [""]]];
if (isNull _display) exitWith {false};
private _source = _display getVariable ["Waldo_SupplyTransfers_Source", objNull];
private _destination = _display getVariable ["Waldo_SupplyTransfers_Destination", objNull];
private _list = _display getVariable ["Waldo_SupplyTransfers_Items", controlNull];
private _queueList = _display getVariable ["Waldo_SupplyTransfers_QueueList", controlNull];
private _quantityControl = _display getVariable ["Waldo_SupplyTransfers_Quantity", controlNull];
private _status = _display getVariable ["Waldo_SupplyTransfers_Status", controlNull];
if (isNull _source || {isNull _destination}) exitWith {false};
if (_display getVariable ["Waldo_SupplyTransfers_Pending", false]) exitWith {
    if (!isNull _status) then {_status ctrlSetText "Wait for the current transfer result before changing the list."};
    false
};
private _queue = +(_display getVariable ["Waldo_SupplyTransfers_Queue", []]);
if (_mode == "CLEAR") exitWith {
    _display setVariable ["Waldo_SupplyTransfers_Queue", []];
    if (!isNull _status) then {_status ctrlSetText "Transfer list cleared."};
    [_display] call Waldo_fnc_SupplyTransfersRefreshLocal;
    true
};
if (_mode == "REMOVE") exitWith {
    private _index = if (isNull _queueList) then {-1} else {lbCurSel _queueList};
    if (_index < 0 || {_index >= count _queue}) exitWith {false};
    _queue deleteAt _index;
    _display setVariable ["Waldo_SupplyTransfers_Queue", _queue];
    if (!isNull _status) then {_status ctrlSetText "Line removed. Review the remaining transfer list."};
    [_display] call Waldo_fnc_SupplyTransfersRefreshLocal;
    true
};
if (_mode in ["ADD", "ADD_ALL"]) exitWith {
    private _selectedIndex = if (isNull _list) then {-1} else {lbCurSel _list};
    private _selection = (_display getVariable ["Waldo_SupplyTransfers_Rows", []]) param [_selectedIndex, []];
    if (_selection isEqualTo []) exitWith {false};
    _selection params ["_category", "_row", "_available", "_name", "_detail"];
    private _existing = _queue findIf {(_x select 0) isEqualTo _category && {(_x select 1) isEqualTo _row}};
    private _queued = if (_existing < 0) then {0} else {(_queue select _existing) select 2};
    private _remaining = _available - _queued;
    private _quantity = if (_mode == "ADD_ALL") then {_remaining} else {
        if (isNull _quantityControl) then {0} else {parseNumber ctrlText _quantityControl}
    };
    if (_quantity < 1 || {_quantity != floor _quantity} || {_quantity > _remaining}) exitWith {
        if (!isNull _status) then {_status ctrlSetText format ["Enter a whole quantity from 1 to %1 not already listed.", _remaining max 0]};
        false
    };
    if (_existing < 0) then {
        _queue pushBack [_category, _row, _quantity, _name, _detail];
    } else {
        private _entry = +(_queue select _existing);
        _entry set [2, (_entry select 2) + _quantity];
        _queue set [_existing, _entry];
    };
    _display setVariable ["Waldo_SupplyTransfers_Queue", _queue];
    if (!isNull _status) then {_status ctrlSetText format ["%1 line(s) ready. Add more, or transfer the list.", count _queue]};
    [_display] call Waldo_fnc_SupplyTransfersRefreshLocal;
    true
};
if (_mode != "SEND" || {_queue isEqualTo []} || {_display getVariable ["Waldo_SupplyTransfers_Pending", false]}) exitWith {
    if (!isNull _status) then {_status ctrlSetText "Add at least one line, or wait for the current transfer result."};
    false
};
private _interaction = _display getVariable ["Waldo_SupplyTransfers_InteractionObject", _source];
if (player distance _interaction > 6) exitWith {
    if (!isNull _status) then {_status ctrlSetText "Move within 6 metres of the box or vehicle you opened."};
    false
};
private _moves = _queue apply {[_x select 0, _x select 1, _x select 2]};
_display setVariable ["Waldo_SupplyTransfers_Pending", true];
_display setVariable ["Waldo_SupplyTransfers_PendingSource", _source];
if (!isNull _status) then {_status ctrlSetText format ["Checking %1 line(s), capacity and distance on the server...", count _moves]};
[player, _source, _destination, "BATCH", _moves, 1, _interaction]
    remoteExecCall ["Waldo_fnc_SupplyTransfersRequestWithFeedbackServer", 2];
true
