/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - validateImportPayload
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_validateImportPayload via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_payload"];

    if !(_payload isEqualType []) exitWith {false};
    if ((count _payload) < 4) exitWith {false};
    private _version = _payload param [0, ""];
    if !(_version in ["WaldoEcoResource_CONFIG_V1", "WaldoEcoResource_CONFIG_V2", "WaldoEcoResource_CONFIG_V3"]) exitWith {false};

    private _types = _payload param [1, []];
    private _includeValues = _payload param [2, false];
    private _sideData = _payload param [3, []];

    if !(_types isEqualType []) exitWith {false};
    if ((count _types) <= 0) exitWith {false};
    if !(_includeValues isEqualType true) exitWith {false};
    if !(_sideData isEqualType []) exitWith {false};

    true
