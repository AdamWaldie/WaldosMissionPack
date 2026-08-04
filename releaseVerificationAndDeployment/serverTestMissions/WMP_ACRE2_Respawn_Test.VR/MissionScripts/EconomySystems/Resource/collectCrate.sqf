/*
 * Author: WaldoTheWarfighter
 * Collect crate.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _crate <ANY> - crate
 * 1: _caller <ANY> - caller
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_crate, _caller] call Waldo_fnc_EcoResource_collectCrate;
 */

    params ["_crate", "_caller"];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
    if (isNull _crate) exitWith {};
    if (isNull _caller) exitWith {};
    if (!alive _caller) exitWith {};
    if (_crate getVariable ["WaldoEcoResource_Collected", false]) exitWith {};

    _crate setVariable ["WaldoEcoResource_Collected", true, true];

    private _resourceRows = [_crate] call Waldo_fnc_EcoResource_getCrateResourceRows;
    private _sideKey = [side group _caller] call Waldo_fnc_EcoResource_getSideKeyFromSide;
    private _result = [_sideKey, _resourceRows, name _caller] call Waldo_fnc_EcoResource_applyResourceRowsToSide;
    private _appliedRows = _result param [0, []];
    private _leftoverRows = _result param [1, []];

    private _appliedText = (_appliedRows apply {
        format ["%1 +%2", _x param [0, "Resource"], _x param [1, 0]]
    }) joinString ", ";
    private _leftoverText = (_leftoverRows apply {
        format ["%1 %2", _x param [0, "Resource"], _x param [1, 0]]
    }) joinString ", ";

    if ((count _leftoverRows) > 0) then {
        private _primaryType = [_leftoverRows] call Waldo_fnc_EcoResource_getPrimaryResourceType;
        private _primaryAmount = (_leftoverRows select 0) param [1, 1];
        _crate setVariable ["WaldoEcoResource_ResourceRows", _leftoverRows, true];
        _crate setVariable ["WaldoEcoResource_ResourceType", _primaryType, true];
        _crate setVariable ["WaldoEcoResource_ResourceValue", _primaryAmount, true];
        [_crate] call Waldo_fnc_EcoResource_refreshCrateMarker;
        _crate setVariable ["WaldoEcoResource_Collected", false, true];

        private _message = if (_appliedText isEqualTo "") then {
            format ["Nothing collected: storage is full. Container remains with %1.", _leftoverText]
        } else {
            format ["Collected %1. Container remains because storage is full; remaining: %2.", _appliedText, _leftoverText]
        };
        [_caller, _message] call Waldo_fnc_EcoCore_notifyActor;
        diag_log format ["[WMP ECO] Partial crate collection crate=%1 actor=%2 applied=%3 remaining=%4", netId _crate, name _caller, _appliedRows, _leftoverRows];
    } else {
        private _crateId = netId _crate;
        [_crate, "WaldoEcoResource_CollectActionAddedLocal"] call Waldo_fnc_EcoCore_clearZeusObjectAction;
        [_crate] call Waldo_fnc_EcoResource_deleteCrateMarker;
        // Hide and disable immediately while Arma propagates network-object deletion.
        _crate hideObjectGlobal true;
        _crate enableSimulationGlobal false;
        deleteVehicle _crate;
        [_caller, format ["Resources collected%1. Empty container removed.", if (_appliedText isEqualTo "") then {""} else {": " + _appliedText}]] call Waldo_fnc_EcoCore_notifyActor;
        diag_log format ["[WMP ECO] Full crate collection crate=%1 actor=%2 applied=%3 deleteRequested=true", _crateId, name _caller, _appliedRows];
        [_crate, _crateId] spawn {
            params ["_crate", "_crateId"];
            uiSleep 0.25;
            if (!isNull _crate) then {
                // A locally owned inventory container can survive the first
                // deletion frame. Keep it hidden and retry once on authority.
                deleteVehicle _crate;
                uiSleep 0.75;
            };
            if (isNull _crate) then {
                diag_log format ["[WMP ECO] Crate deletion confirmed crate=%1", _crateId];
            } else {
                diag_log format ["[WMP ECO][RESOURCE][ERROR] crate deletion failed crate=%1 owner=%2 local=%3", _crateId, owner _crate, local _crate];
            };
        };
    };
