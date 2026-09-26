/*
 * Author: WaldoTheWarfighter
 * Resolves an icon path to a valid CfgMarkers type for a building marker.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _iconPath <STRING> - icon path (optional, default: "")
 *
 * Return Value:
 * <STRING> marker type, defaulting to mil_dot.
 *
 * Example:
 * [_iconPath] call Waldo_fnc_EcoBuild_getBuildMarkerClass;
 * Locality/Authority: Any machine; pure marker-config lookup.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Building marker refresh.
 * Result: Unknown icons use the vanilla dot marker.
 */

        params [["_iconPath", ""]];

        private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
        private _index = _choices findIf {
            ((_x param [1, ""]) isEqualTo _iconPath)
        };

        if (_index < 0) exitWith {"mil_dot"};
        (_choices select _index) param [0, "mil_dot"]

