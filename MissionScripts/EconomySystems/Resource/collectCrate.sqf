/*
 * Author: Waldo
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
    private _leftoverRows = _result param [1, []];

    if ((count _leftoverRows) > 0) then {
        private _primaryType = [_leftoverRows] call Waldo_fnc_EcoResource_getPrimaryResourceType;
        private _primaryAmount = (_leftoverRows select 0) param [1, 1];
        _crate setVariable ["WaldoEcoResource_ResourceRows", _leftoverRows, true];
        _crate setVariable ["WaldoEcoResource_ResourceType", _primaryType, true];
        _crate setVariable ["WaldoEcoResource_ResourceValue", _primaryAmount, true];
        [_crate] call Waldo_fnc_EcoResource_refreshCrateMarker;
        _crate setVariable ["WaldoEcoResource_Collected", false, true];
    } else {
        [_crate, "WaldoEcoResource_CollectActionAddedLocal"] call Waldo_fnc_EcoCore_clearPubZeusObjectAction;
        [_crate] call Waldo_fnc_EcoResource_deleteCrateMarker;
        deleteVehicle _crate;
    };
