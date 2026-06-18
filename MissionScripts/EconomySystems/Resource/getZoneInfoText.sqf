/*
 * Author: Waldo
 * Get zone info text.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _zoneId <STRING> - zone id (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_zoneId] call Waldo_fnc_EcoResource_getZoneInfoText;
 */

    params [["_zoneId", ""]];

    private _zones = call Waldo_fnc_EcoResource_getResourceZones;
    private _index = _zones findIf {((_x param [0, ""]) isEqualTo _zoneId)};
    if (_index < 0) exitWith {"AREA INFORMATION\n\nArea no longer exists."};

    private _zone = _zones select _index;
    private _remaining = 0 max ((_zone param [7, 60]) - (serverTime - (_zone param [8, 0])));
    private _resourceRows = [_zone] call Waldo_fnc_EcoResource_getZoneResourceRows;

    format [
        "AREA INFORMATION\n\nName: %1\nResources: %2\nGeneration Interval: %3 sec\nOwner: %4\nNext Tick: %5 sec",
        _zone param [1, "Zone"],
        [_resourceRows] call Waldo_fnc_EcoResource_getZoneResourceRowsSummaryText,
        _zone param [7, 60],
        [(_zone param [5, "NONE"])] call Waldo_fnc_EcoResource_getZoneOwnerLabel,
        round _remaining
    ]
