/*
 * Author: WaldoTheWarfighter
 * Purpose: Spawn a collectible economy resource case with its resource rows,
 * marker and ACE Drag/Carry. This case is not an inventory crate and does not
 * join Supply Transfers or Physical Cargo automatically.
 * Locality / Authority: Economy authority creates and tags the case. ACE
 * portability is published globally from the server.
 * Repeat / JIP: Each call creates one new case. Resource and ACE state replay
 * to joining clients through their existing global setup paths.
 *
 * Arguments:
 * 0: position <ARRAY>
 * 1: resource rows <ARRAY> (default [])
 * 2: legacy value <NUMBER> (default 1)
 *
 * Return Value:
 * <OBJECT> - created resource case.
 *
 * Example:
 * [getPosATL player, [["Money", 5]]] call Waldo_fnc_EcoResource_spawnResourceCrate;
 * Current callers: economy resource-zone and scripted resource spawns.
 */

    params ["_pos", ["_resourceRows", []], ["_legacyValue", 1]];

    // Authority-only creation; forward to the server when called on a client (dedicated-safe).
    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {
        _this remoteExec ["Waldo_fnc_EcoResource_spawnResourceCrate", 2];
    };

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
    [_crate] call Waldo_fnc_CargoAttributesPrepareObject;

    [_crate, true] call Waldo_fnc_EcoResource_registerCuratorEditableObject;

    _crate setVariable ["WaldoEcoResource_IsResourceCrate", true, true];
    _crate setVariable ["WaldoEcoResource_Collected", false, true];
    _crate setVariable ["WaldoEcoResource_ResourceRows", _safeRows, true];
    _crate setVariable ["WaldoEcoResource_ResourceType", _primaryType, true];
    _crate setVariable ["WaldoEcoResource_ResourceValue", _primaryAmount, true];
    [_crate, "CRATES"] call Waldo_fnc_EcoCore_registerRuntimeObject;
    [_crate] call Waldo_fnc_EcoResource_trackCrateMarker;

    if (hasInterface) then {
        [_crate] call Waldo_fnc_EcoResource_ensureCrateActionLocal;
    };
    diag_log format ["[WMP ECO] Resource crate created crate=%1 position=%2 rows=%3 authority=%4", netId _crate, getPosATL _crate, _safeRows, clientOwner];
    _crate
