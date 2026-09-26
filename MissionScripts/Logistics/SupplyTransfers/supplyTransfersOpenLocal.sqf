/*
 * Author: WaldoTheWarfighter
 * Purpose: Opens a box/vehicle transfer panel with nearby destinations and a move queue.
 * Locality / Authority: Interface-local only; the server validates and commits every request.
 * Repeat / JIP: Reopening replaces the prior modal; no durable client state is required.
 * Arguments: source <OBJECT>; preferred vehicle destination <OBJECT> (objNull).
 * Return Value: <DISPLAY> or displayNull.
 * Current callers: registered-crate and registered-vehicle ACE transfer actions.
 * Example: [myCrate] call Waldo_fnc_SupplyTransfersOpenLocal;
 * Result: The player receives the transfer panel for the selected source.
 */
params [["_source", objNull, [objNull]], ["_preferredDestination", objNull, [objNull]]];
private _interaction = if (isNull _preferredDestination) then {_source} else {_preferredDestination};
if (!hasInterface || {isNull _source} || {player distance _interaction > 6}) exitWith {displayNull};
private _destinations = [_source] call Waldo_fnc_SupplyTransfersDestinationsLocal;
if (!isNull _preferredDestination && {!(_preferredDestination in _destinations)}) exitWith {
    ["SUPPLY TRANSFER", "The selected box is too far from this vehicle, or the vehicle has no inventory capacity.",
        "WARNING", "SUPPLY_TRANSFER_UI"] call Waldo_fnc_FeatureNotifyLocal;
    displayNull
};
if (_destinations isEqualTo []) exitWith {
    ["SUPPLY TRANSFER", "No cargo-capable box or vehicle is within transfer range.", "WARNING", "SUPPLY_TRANSFER_UI"] call Waldo_fnc_FeatureNotifyLocal;
    displayNull
};
private _display = ["  WMP  //  SUPPLY TRANSFER", true] call Waldo_fnc_EcoCore_createZeusPromptDisplay;
if (isNull _display) exitWith {displayNull};
private _theme = _display getVariable ["WaldoEcoCore_PromptTheme", [] call Waldo_fnc_UiTheme];
_display setVariable ["Waldo_SupplyTransfers_Source", _source];
_display setVariable ["Waldo_SupplyTransfers_InteractionObject", _interaction];
_display setVariable ["Waldo_SupplyTransfers_Destinations", _destinations];
_display setVariable ["Waldo_SupplyTransfers_Queue", []];

private _text = {
    params ["_class", "_position", "_label"];
    private _control = _display ctrlCreate [_class, -1];
    _control ctrlSetPosition _position;
    _control ctrlSetText _label;
    _control ctrlSetTextColor (_theme getOrDefault ["text", [0.9, 0.96, 1, 1]]);
    _control ctrlCommit 0;
    _control
};
private _sourceIsVehicle = _source isKindOf "LandVehicle" || {_source isKindOf "Air"} || {_source isKindOf "Ship"};
["RscText", [0.18, 0.18, 0.62, 0.035],
    if (isNull _preferredDestination) then {
        if (_sourceIsVehicle) then {"FROM THIS VEHICLE  ->  CHOOSE DESTINATION"} else {"FROM THIS BOX  ->  CHOOSE DESTINATION"}
    } else {"FROM SELECTED SOURCE  ->  THIS VEHICLE"}] call _text;
private _sourceName = _source getVariable ["Waldo_QM_IssueName", ""];
if (_sourceName isEqualTo "") then {_sourceName = getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName")};
if (_sourceName isEqualTo "") then {_sourceName = typeOf _source};
["RscText", [0.18, 0.22, 0.30, 0.04], _sourceName] call _text;
private _destinationCombo = _display ctrlCreate ["RscCombo", -1];
_destinationCombo ctrlSetPosition [0.51, 0.22, 0.29, 0.04];
_destinationCombo ctrlCommit 0;
_display setVariable ["Waldo_SupplyTransfers_DestinationCombo", _destinationCombo];
{
    private _name = _x getVariable ["Waldo_QM_IssueName", ""];
    if (_name isEqualTo "") then {_name = getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName")};
    if (_name isEqualTo "") then {_name = typeOf _x};
    _destinationCombo lbAdd format ["%1  (%2 m)", _name, round (_x distance _source)];
} forEach _destinations;
_destinationCombo lbSetCurSel (if (isNull _preferredDestination) then {0} else {_destinations find _preferredDestination});
if (!isNull _preferredDestination) then {_destinationCombo ctrlEnable false};
private _capacity = ["RscText", [0.18, 0.275, 0.62, 0.032], ""] call _text;
_display setVariable ["Waldo_SupplyTransfers_Capacity", _capacity];
["RscText", [0.18, 0.32, 0.62, 0.03], "SELECT SUPPLIES TO MOVE"] call _text;
private _items = _display ctrlCreate ["RscListbox", -1];
_items ctrlSetPosition [0.18, 0.355, 0.62, 0.20];
_items ctrlCommit 0;
_display setVariable ["Waldo_SupplyTransfers_Items", _items];
["RscText", [0.18, 0.57, 0.17, 0.036], "QUANTITY"] call _text;
private _quantity = _display ctrlCreate ["RscEdit", -1];
_quantity ctrlSetPosition [0.35, 0.57, 0.10, 0.036];
_quantity ctrlSetText "1";
_quantity ctrlCommit 0;
_display setVariable ["Waldo_SupplyTransfers_Quantity", _quantity];
private _add = ["RscButton", [0.48, 0.57, 0.15, 0.04], "ADD TO LIST"] call _text;
private _addAll = ["RscButton", [0.65, 0.57, 0.15, 0.04], "ALL OF TYPE"] call _text;
["RscText", [0.18, 0.625, 0.62, 0.03], "REVIEW ITEMS TO TRANSFER"] call _text;
private _queueList = _display ctrlCreate ["RscListbox", -1];
_queueList ctrlSetPosition [0.18, 0.66, 0.62, 0.13];
_queueList ctrlCommit 0;
_display setVariable ["Waldo_SupplyTransfers_QueueList", _queueList];
private _remove = ["RscButton", [0.18, 0.805, 0.14, 0.04], "REMOVE LINE"] call _text;
private _clear = ["RscButton", [0.34, 0.805, 0.12, 0.04], "CLEAR LIST"] call _text;
private _move = ["RscButton", [0.48, 0.805, 0.18, 0.04], "TRANSFER LIST"] call _text;
private _close = ["RscButton", [0.68, 0.805, 0.12, 0.04], "CLOSE"] call _text;
private _status = ["RscText", [0.18, 0.855, 0.62, 0.038], "Add one or more items, then transfer the list together."] call _text;
_display setVariable ["Waldo_SupplyTransfers_Status", _status];
_destinationCombo ctrlAddEventHandler ["LBSelChanged", {
    private _panel = ctrlParent (_this select 0);
    if (_panel getVariable ["Waldo_SupplyTransfers_Pending", false]) then {
        private _old = (_panel getVariable ["Waldo_SupplyTransfers_Destinations", []])
            find (_panel getVariable ["Waldo_SupplyTransfers_Destination", objNull]);
        if (_old >= 0 && {lbCurSel (_this select 0) != _old}) then {(_this select 0) lbSetCurSel _old};
    } else {
        _panel setVariable ["Waldo_SupplyTransfers_Queue", []];
        [_panel] call Waldo_fnc_SupplyTransfersRefreshLocal;
    };
}];
_items ctrlAddEventHandler ["LBSelChanged", {
    private _display = ctrlParent (_this select 0);
    (_display getVariable ["Waldo_SupplyTransfers_Quantity", controlNull]) ctrlSetText "1";
}];
_add ctrlAddEventHandler ["ButtonClick", {[(ctrlParent (_this select 0)), "ADD"] call Waldo_fnc_SupplyTransfersSubmitLocal}];
_addAll ctrlAddEventHandler ["ButtonClick", {[(ctrlParent (_this select 0)), "ADD_ALL"] call Waldo_fnc_SupplyTransfersSubmitLocal}];
_remove ctrlAddEventHandler ["ButtonClick", {[(ctrlParent (_this select 0)), "REMOVE"] call Waldo_fnc_SupplyTransfersSubmitLocal}];
_clear ctrlAddEventHandler ["ButtonClick", {[(ctrlParent (_this select 0)), "CLEAR"] call Waldo_fnc_SupplyTransfersSubmitLocal}];
_move ctrlAddEventHandler ["ButtonClick", {[(ctrlParent (_this select 0)), "SEND"] call Waldo_fnc_SupplyTransfersSubmitLocal}];
_close ctrlAddEventHandler ["ButtonClick", {(ctrlParent (_this select 0)) closeDisplay 2}];
[_display] call Waldo_fnc_SupplyTransfersRefreshLocal;
[_display] call Waldo_fnc_EcoCore_fitPromptDisplay;
_display
