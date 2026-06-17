/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getZoneOwnerFlagMarkerClass
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getZoneOwnerFlagMarkerClass via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_sideKey", "NONE"]];

    private _candidates = switch (toUpper _sideKey) do {
        case "WEST": {["flag_NATO"]};
        case "EAST": {["flag_CSAT"]};
        case "GUER": {["flag_Altis", "flag_AAF", "flag_FIA"]};
        default {[]};
    };

    private _index = _candidates findIf {
        isClass (configFile >> "CfgMarkers" >> _x)
    };

    if (_index < 0) exitWith {""};
    _candidates select _index
