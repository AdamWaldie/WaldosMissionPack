/*
 * Author: Waldo
 * Spawn resource crate.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _pos <ANY> - pos
 * 1: _resourceRows <ARRAY> - resource rows (optional, default: [])
 * 2: _legacyValue <SCALAR> - legacy value (optional, default: 1)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_pos, _resourceRows, _legacyValue] call Waldo_fnc_EcoResource_spawnResourceCrate;
 */

    params ["_pos", ["_resourceRows", []], ["_legacyValue", 1]];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _safeRows = if (_resourceRows isEqualType []) then {
        [_resourceRows] call Waldo_fnc_EcoResource_normalizeResourceRows
    } else {
        [[[_resourceRows] call Waldo_fnc_EcoResource_normalizeResourceName, 1 max (floor _legacyValue)]] call Waldo_fnc_EcoResource_normalizeResourceRows
    };
    if ((count _safeRows) <= 0) then {
        _safeRows = [["Resource", 1]];
    };
    private _primaryType = [_safeRows] call Waldo_fnc_EcoResource_getPrimaryResourceType;
    private _primaryAmount = (_safeRows select 0) param [1, 1];

    private _crate = createVehicle ["Land_PlasticCase_01_medium_F", _pos, [], 0, "CAN_COLLIDE"];
    _crate setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];

    [_crate, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;

    _crate setVariable ["WaldoEcoResource_IsResourceCrate", true, true];
    _crate setVariable ["WaldoEcoResource_Collected", false, true];
    _crate setVariable ["WaldoEcoResource_ResourceRows", _safeRows, true];
    _crate setVariable ["WaldoEcoResource_ResourceType", _primaryType, true];
    _crate setVariable ["WaldoEcoResource_ResourceValue", _primaryAmount, true];
    [_crate] call Waldo_fnc_EcoResource_trackCrateMarker;

    if (hasInterface) then {
        [_crate] call Waldo_fnc_EcoResource_ensureCrateActionLocal;
    };
