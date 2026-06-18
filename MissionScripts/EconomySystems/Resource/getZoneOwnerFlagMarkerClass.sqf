/*
 * Author: Waldo
 * Get zone owner flag marker class.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey] call Waldo_fnc_EcoResource_getZoneOwnerFlagMarkerClass;
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
